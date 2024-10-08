//
//  WalletsDataService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import Foundation
import Combine

final class WalletsDataService {
    
    private let queue = DispatchQueue(label: "com.unstoppable.wallets.data")
    private let storage = WalletEntitiesStorage.instance
    private let domainsService: UDDomainsServiceProtocol
    private let walletsService: UDWalletsServiceProtocol
    private let transactionsService: DomainTransactionsServiceProtocol
    private let walletConnectServiceV2: WalletConnectServiceV2Protocol
    private let walletNFTsService: WalletNFTsServiceProtocol
    private let mpcWalletsService: MPCWalletsServiceProtocol
    private let networkService: WalletsDataNetworkServiceProtocol
    private let numberOfDomainsToLoadPerTime = 30
    private var refreshDomainsTimer: AnyCancellable?

    @Published private(set) var wallets: [WalletEntity] = []
    var walletsPublisher: Published<[WalletEntity]>.Publisher  { $wallets }
    @Published private(set) var selectedWallet: WalletEntity? = nil
    var selectedWalletPublisher: Published<WalletEntity?>.Publisher { $selectedWallet }
    
    init(domainsService: UDDomainsServiceProtocol,
         walletsService: UDWalletsServiceProtocol,
         transactionsService: DomainTransactionsServiceProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol,
         walletNFTsService: WalletNFTsServiceProtocol,
         mpcWalletsService: MPCWalletsServiceProtocol,
         networkService: WalletsDataNetworkServiceProtocol) {
        self.domainsService = domainsService
        self.walletsService = walletsService
        self.transactionsService = transactionsService
        self.walletConnectServiceV2 = walletConnectServiceV2
        self.walletNFTsService = walletNFTsService
        self.mpcWalletsService = mpcWalletsService
        self.networkService = networkService
        walletsService.addListener(self)
        wallets = storage.getCachedWallets()
        queue.async {
            self.ensureConsistencyWithUDWallets()
        }
    }
    
}

// MARK: - WalletsDataServiceProtocol
extension WalletsDataService: WalletsDataServiceProtocol {
    func setSelectedWallet(_ wallet: WalletEntity?) {
        guard wallet?.address != selectedWallet?.address else { return }
        
        selectedWallet = wallet
        if let wallet {
            refreshDataForWalletAsync(wallet)
        }
    }
    
    func refreshDataForWallet(_ wallet: WalletEntity) async throws  {
        await refreshDataForWalletSync(wallet)
    }
    
    func didChangeEnvironment() {
        wallets.forEach { wallet in
            refreshDataForWalletAsync(wallet)
        }
    }
    
    func didPurchaseDomains(_ purchasedDomains: [PendingPurchasedDomain],
                            pendingProfiles: [DomainProfilePendingChanges]) async {
        guard !purchasedDomains.isEmpty,
              let wallet = wallets.findWithAddress(purchasedDomains[0].walletAddress) else { return }
        
        var domains = wallet.domains
        let purchasedDomainsDisplayInfo = await transformPendingPurchasedDomainToDomainsWithInfo(purchasedDomains,
                                                                                                     pendingProfiles: pendingProfiles).map { $0.displayInfo }
        domains.append(contentsOf: purchasedDomainsDisplayInfo)
        mutateWalletEntity(wallet) { wallet in
            wallet.updateDomains(domains)
        }
    }
    
    func didMintDomainsWith(domainNames: [String],
                            to wallet: WalletEntity) -> [MintingDomain] {
        guard !domainNames.isEmpty else { return [] }
        
        let transactions = domainNames.map { TransactionItem(id: 0,
                                                         domainName: $0,
                                                         isPending: true,
                                                         type: .maticTx,
                                                         operation: .mintDomain) }
        transactionsService.cacheTransactions(transactions)
        
        let mintingDomains = domainNames.map { MintingDomain(name: $0,
                                                         walletAddress: wallet.address,
                                                         isPrimary: false,
                                                         transactionHash: nil) }
        
        var currentMintingDomains = MintingDomainsStorage.retrieveMintingDomains()
        currentMintingDomains.append(contentsOf: mintingDomains)
        try? MintingDomainsStorage.save(mintingDomains: currentMintingDomains)
        let newDomains = createDomainsFrom(mintingDomains: mintingDomains,
                                        pfpInfo: [],
                                        reverseResolutionDomainName: nil).map { $0.displayInfo }
        var domains = wallet.domains
        domains.append(contentsOf: newDomains)
        mutateWalletEntity(wallet) { wallet in
            wallet.updateDomains(domains)
        }
        
        return mintingDomains
    }
    
    func refreshDataForWalletDomain(_ domainName: DomainName) async throws {
        guard let wallet = wallets.first(where: { $0.isOwningDomain(domainName) }) else { throw WalletsDataServiceError.walletNotFound }
        
        try await refreshDataForWallet(wallet)
    }
    
    func loadBalanceFor(walletAddress: HexAddress) async throws -> [WalletTokenPortfolio] {
        try await networkService.fetchCryptoPortfolioFor(wallet: walletAddress)
    }
    
    func loadAdditionalBalancesFor(domainName: DomainName) async -> [WalletTokenPortfolio] {
        let cachedBalances = WalletBalancesStorage.instance.getCachedBalancesFor(domainName: domainName)
        do {
            let additionalAddresses = try await getAdditionalWalletAddressesToLoadBalanceFor(domainName: domainName)
            guard !additionalAddresses.isEmpty else { return [] }
            
            let balances = await loadAdditionalBalancesFor(addresses: additionalAddresses,
                                                           using: cachedBalances)
            WalletBalancesStorage.instance.cacheBalances(balances, for: domainName)
            
            return balances
        } catch {
            Debugger.printFailure("Failed to load additional tokens for domain: \(domainName)")
            return cachedBalances
        }
    }
}

// MARK: - UDWalletsServiceListener
extension WalletsDataService: UDWalletsServiceListener {
    func walletsDataUpdated(notification: UDWalletsServiceNotification) {
        Task {
            switch notification {
            case .walletsUpdated:
                /// ATM put delay to fix issue when wallet's state is not external immediately after this notification trigerred
                await Task.sleep(seconds: 0.2)
                udWalletsUpdated()
            case .reverseResolutionDomainChanged(let domainName, _):
                if let wallet = wallets.first(where: { $0.isOwningDomain(domainName) }),
                   var domain = wallet.domains.first(where: { $0.name == domainName }) {
                    domain.setState(.updatingReverseResolution)
                    mutateWalletEntity(wallet) { wallet in
                        wallet.changeRRDomain(domain)
                    }
                    refreshWalletDomainsNonBlocking(wallet, shouldRefreshPFP: false)
                    AppReviewService.shared.appReviewEventDidOccurs(event: .didSetRR)
                }
            case .walletRemoved:
                return
            }
        }
    }
    
    private func udWalletsUpdated() {
        ensureConsistencyWithUDWallets()
        let updatedSelectedWallet = wallets.first(where: { $0.address == selectedWallet?.address })
        if updatedSelectedWallet != nil {
            selectedWallet = updatedSelectedWallet
        }
        walletConnectServiceV2.disconnectAppsForAbsentWallets(from: wallets)
    }
}

// MARK: - Private methods
private extension WalletsDataService {
    func refreshDataForWalletAsync(_ wallet: WalletEntity, shouldRefreshPFP: Bool = true) {
        refreshWalletDomainsNonBlocking(wallet, shouldRefreshPFP: shouldRefreshPFP)
        refreshWalletBalancesAsync(wallet)
        refreshWalletNFTsAsync(wallet)
    }
    
    func refreshDataForWalletSync(_ wallet: WalletEntity) async {
        async let domainsTask: () = refreshWalletDomains(wallet, shouldRefreshPFP: true)
        async let walletsTask: () = refreshWalletBalancesAsync(wallet)
        async let NFTsTask: () = refreshWalletNFTsSync(wallet)
        
        await (_) = (domainsTask, walletsTask, NFTsTask)
    }
    
    func getUDWallets() -> [UDWallet] {
        walletsService.getUserWallets()
    }
    
    func mutateWalletEntity(_ wallet: WalletEntity, mutationBlock: (inout WalletEntity)->()) {
        queue.sync {
            guard let i = wallets.firstIndex(where: { $0.address == wallet.address }) else { return }
            
            mutationBlock(&wallets[i])
            if wallet.address == selectedWallet?.address {
                selectedWallet = wallets[i]
            }
            storage.cacheWallets(wallets)
        }
    }
}

// MARK: - Load domains
private extension WalletsDataService {
    func refreshWalletDomainsNonBlocking(_ wallet: WalletEntity, shouldRefreshPFP: Bool) {
        Task {
            await refreshWalletDomains(wallet, shouldRefreshPFP: shouldRefreshPFP)
        }
    }

    func refreshWalletDomains(_ wallet: WalletEntity, shouldRefreshPFP: Bool) async {
        await stopRefreshDomainsTimer()
        do {
            async let domainsTask = domainsService.updateDomainsList(for: [wallet.udWallet])
            async let reverseResolutionTask = fetchRRDomainNameFor(wallet: wallet)
            let (domains, reverseResolutionDomainName) = try await (domainsTask, reverseResolutionTask)
            let mintingDomainsNames = MintingDomainsStorage.retrieveMintingDomainsFor(walletAddress: wallet.address).map({ $0.name })
            let pendingPurchasedDomains = getPurchasedDomainsUnlessInList(domains, for: wallet.address)
            
            if domains.isEmpty,
               mintingDomainsNames.isEmpty,
               pendingPurchasedDomains.isEmpty {
                mutateWalletEntity(wallet) { wallet in
                    wallet.updateDomains([])
                }
                return
            }
            
            async let transactionsTask = transactionsService.updatePendingTransactionsListFor(domains: domains.map({ $0.name }) + mintingDomainsNames)
            async let domainsPFPInfoTask = loadDomainsPFPIfNotTooLarge(domains)
            let (transactions, domainsPFPInfo) = try await (transactionsTask, domainsPFPInfoTask)
            
            await buildWalletDomainsDisplayInfoData(wallet: wallet,
                                                    domains: domains,
                                                    pfpInfo: domainsPFPInfo,
                                                    withTransactions: transactions,
                                                    reverseResolutionDomainName: reverseResolutionDomainName)
            
            if shouldRefreshPFP {
                await loadWalletDomainsPFPIfTooLarge(wallet)
            }
        } catch { }
        startRefreshDomainsTimerIfNeeded()
    }
    
    func buildWalletDomainsDisplayInfoData(wallet: WalletEntity,
                                           domains: [DomainItem],
                                           pfpInfo: [DomainPFPInfo],
                                           withTransactions pendingTransactions: [TransactionItem],
                                           reverseResolutionDomainName: DomainName?) async {
        
        var reverseResolutionDomainName = reverseResolutionDomainName
        if let setRRTransaction = pendingTransactions.filterPending(extraCondition: { $0.operation == .setReverseResolution }).first {
            reverseResolutionDomainName = setRRTransaction.domainName
        } else if let removeRRTransaction = pendingTransactions.filterPending(extraCondition: { $0.operation == .removeReverseResolution }).first,
                  removeRRTransaction.domainName == reverseResolutionDomainName {
            reverseResolutionDomainName = nil
        }
        let pendingProfiles = PurchasedDomainsStorage.retrievePendingProfiles()
        
        // Aggregate domain display info
        var domainsWithDisplayInfo = [DomainWithDisplayInfo]()
        for domain in domains {
            var domainState: DomainDisplayInfo.State = .default
            if pendingTransactions.filterPending(extraCondition: { $0.operation == .transferDomain }).first(where: { $0.domainName == domain.name }) != nil {
                domainState = .transfer
            } else if pendingTransactions.containMintingInProgress(domain) {
                domainState = .transfer
            } else if pendingTransactions.containReverseResolutionOperationProgress(domain) {
                domainState = .updatingReverseResolution
            } else if pendingTransactions.containPending(domain) {
                domainState = .updatingRecords
            }
            
            let domainPFPInfo = await resolveDomainPFPInfo(for: domain.name, using: pfpInfo, pendingProfiles: pendingProfiles) // pfpInfo.first(where: { $0.domainName == domain.name })
            let order = SortDomainsManager.shared.orderFor(domainName: domain.name)
            let domainDisplayInfo = DomainDisplayInfo(domainItem: domain,
                                                      pfpInfo: domainPFPInfo,
                                                      state: domainState,
                                                      order: order,
                                                      isSetForRR: reverseResolutionDomainName == domain.name)
            
            domainsWithDisplayInfo.append(.init(domain: domain,
                                                displayInfo: domainDisplayInfo))
        }
        
        // Purchased domains
        let pendingPurchasedDomains = getPurchasedDomainsUnlessInList(domains, for: wallet.address)
        let purchasedDomainsWithDisplayInfo = await transformPendingDomainItemsToDomainsWithInfo(pendingPurchasedDomains,
                                                                                                 using: pfpInfo,
                                                                                                 pendingProfiles: pendingProfiles)
        domainsWithDisplayInfo.append(contentsOf: purchasedDomainsWithDisplayInfo)
        
        // Set minting domains
        let mintingTransactions = pendingTransactions.filterPending(extraCondition: { $0.isMintingTransaction() })
        let mintingDomainsNames = mintingTransactions.compactMap({ $0.domainName })
        var mintingDomainsWithDisplayInfoItems = [DomainWithDisplayInfo]()
        
        if !mintingDomainsNames.isEmpty {
            let mintingDomains = createMintingDomainsIn(walletAddress: wallet.address,
                                                        mintingDomainsNames: mintingDomainsNames)
            mintingDomainsWithDisplayInfoItems = createDomainsFrom(mintingDomains: mintingDomains,
                                                                   pfpInfo: pfpInfo,
                                                                   reverseResolutionDomainName: reverseResolutionDomainName)
            
            domainsWithDisplayInfo.remove(domains: mintingDomainsWithDisplayInfoItems)
            try? MintingDomainsStorage.save(mintingDomains: mintingDomains)
        } else {
            MintingDomainsStorage.clearMintingDomains()
        }
        
        let finalDomainsWithDisplayInfo = domainsWithDisplayInfo + mintingDomainsWithDisplayInfoItems
        
        mutateWalletEntity(wallet) { wallet in
            wallet.updateDomains(finalDomainsWithDisplayInfo.map({ $0.displayInfo }))
        }
    }
    
    func createDomainsFrom(mintingDomains: [MintingDomain],
                           pfpInfo: [DomainPFPInfo],
                           reverseResolutionDomainName: DomainName?) -> [DomainWithDisplayInfo] {
        mintingDomains.map({
            let domainName = $0.name
            let domain = DomainItem(name: domainName,
                                    ownerWallet: $0.walletAddress)
            let domainPFPInfo = pfpInfo.first(where: { $0.domainName == domainName })
            let order = SortDomainsManager.shared.orderFor(domainName: domainName)
            
            let displayInfo = DomainDisplayInfo(name: domainName,
                                                ownerWallet: $0.walletAddress,
                                                pfpInfo: domainPFPInfo,
                                                state: .minting,
                                                order: order,
                                                isSetForRR: reverseResolutionDomainName == domainName)
            
            return DomainWithDisplayInfo(domain: domain, displayInfo: displayInfo)
        })
    }
    
    func createMintingDomainsIn(walletAddress: HexAddress,
                                mintingDomainsNames: [String]) -> [MintingDomain] {
        let mintingStoredDomains = MintingDomainsStorage.retrieveMintingDomains().filter({ $0.walletAddress == walletAddress })
        let mintingDomains: [MintingDomain] = mintingDomainsNames.compactMap({ (_ domainName: String) -> MintingDomain? in
            guard let mintingDomain = mintingStoredDomains.first(where: { $0.name == domainName }) else { return nil }
            
            return MintingDomain(name: domainName,
                                 walletAddress: mintingDomain.walletAddress,
                                 isPrimary: false,
                                 transactionHash: mintingDomain.transactionHash)
        })
        return mintingDomains
    }
    
    func resolveDomainPFPInfo(for domainName: String,
                              using pfpInfo: [DomainPFPInfo],
                              pendingProfiles: [DomainProfilePendingChanges]) async -> DomainPFPInfo? {
        if let profile = pendingProfiles.first(where: { $0.domainName == domainName }),
           let localImage = await profile.getAvatarImage() {
            return .init(domainName: domainName, localImage: localImage)
        }
        return pfpInfo.first(where: { $0.domainName == domainName })
    }
    
    func fetchRRDomainNameFor(wallet: WalletEntity) async -> String? {
        do {
            return try await self.walletsService.reverseResolutionDomainName(for: wallet.address)
        } catch {
            /// If request failed to get current RR domain, use cached value
            return wallet.rrDomain?.name
        }
    }
    
    func getPurchasedDomainsUnlessInList(_ domains: [DomainItem],
                                         for walletAddress: String) -> [DomainItem] {
        let pendingPurchasedDomains = PurchasedDomainsStorage.retrievePurchasedDomainsFor(walletAddress: walletAddress).filter({ pendingDomain in
            domains.first(where: { $0.name == pendingDomain.name }) == nil // Purchased domain not yet reflected in the mirror
        })
        let pendingDomains = pendingPurchasedDomains.map {
            DomainItem(name: $0.name,
                       ownerWallet: $0.walletAddress,
                       blockchain: .Matic)
        }
        PurchasedDomainsStorage.setPurchasedDomains(pendingPurchasedDomains)
        return pendingDomains
    }
    
    func transformPendingDomainItemsToDomainsWithInfo(_ pendingPurchasedDomains: [DomainItem],
                                                      using pfpInfo: [DomainPFPInfo],
                                                      pendingProfiles: [DomainProfilePendingChanges]) async -> [DomainWithDisplayInfo] {
        var domainsWithDisplayInfo = [DomainWithDisplayInfo]()
        for domain in pendingPurchasedDomains {
            let order = SortDomainsManager.shared.orderFor(domainName: domain.name)
            let domainPFPInfo = await resolveDomainPFPInfo(for: domain.name,
                                                           using: pfpInfo,
                                                           pendingProfiles: pendingProfiles)
            let domainDisplayInfo = DomainDisplayInfo(domainItem: domain,
                                                      pfpInfo: domainPFPInfo,
                                                      state: .minting,
                                                      order: order,
                                                      isSetForRR: false)
            
            domainsWithDisplayInfo.append(.init(domain: domain,
                                                displayInfo: domainDisplayInfo))
        }
        return domainsWithDisplayInfo
    }
    
    func transformPendingPurchasedDomainToDomainsWithInfo(_ purchasedDomains: [PendingPurchasedDomain],
                                                          pendingProfiles: [DomainProfilePendingChanges]) async -> [DomainWithDisplayInfo] {
        let pendingPurchasedDomains = purchasedDomains.map {
            DomainItem(name: $0.name,
                       ownerWallet: $0.walletAddress,
                       blockchain: .Matic)
        }
        return await transformPendingDomainItemsToDomainsWithInfo(pendingPurchasedDomains,
                                                                  using: [],
                                                                  pendingProfiles: pendingProfiles)
    }
    
    func loadDomainsPFPIfNotTooLarge(_ domains: [DomainItem]) async throws -> [DomainPFPInfo] {
        if domains.count <= numberOfDomainsToLoadPerTime {
            return await domainsService.updateDomainsPFPInfo(for: domains)
        }
        return domainsService.getCachedDomainsPFPInfo()
    }
    
    func loadWalletDomainsPFPIfTooLarge(_ wallet: WalletEntity) async {
        let walletDomains = wallet.domains
        let pendingProfiles = PurchasedDomainsStorage.retrievePendingProfiles()

        if walletDomains.count > numberOfDomainsToLoadPerTime {
            var domains = Array(walletDomains.lazy.sorted { lhs, rhs in
                if lhs.isPrimary {
                    return true
                } else if rhs.isPrimary {
                    return false
                } else if wallet.rrDomain?.name == lhs.name {
                    return true
                } else if wallet.rrDomain?.name == rhs.name {
                    return false
                }
                return false
            })
            
            while !domains.isEmpty {
                let batch = domains.prefix(numberOfDomainsToLoadPerTime).map { $0.name }
                let pfpInfoArray = await domainsService.updateDomainsPFPInfo(for: batch)
                
                if isPFPInfosChanged(pfpInfoArray, in: walletDomains) {
                    mutateWalletEntity(wallet) { wallet in
                        var domains = wallet.domains
                        
                        for pfpInfo in pfpInfoArray {
                            if pendingProfiles.first(where: { $0.domainName == pfpInfo.domainName })?.avatarData == nil,
                               let i = domains.firstIndex(where: { $0.name == pfpInfo.domainName }),
                               domains[i].domainPFPInfo != pfpInfo {
                                domains[i].setPFPInfo(pfpInfo)
                                if domains[i].name == wallet.rrDomain?.name {
                                    wallet.rrDomain = domains[i]
                                }
                            }
                        }
                    }
                }
                
                if Task.isCancelled {
                    break
                }
                domains = Array(domains.dropFirst(batch.count))
            }
        }
    }
    
    func isPFPInfoChanged(_ pfpInfo: DomainPFPInfo, in domains: [DomainDisplayInfo]) -> Bool {
        if let domain = domains.first(where: { $0.name == pfpInfo.domainName }) {
            return domain.domainPFPInfo != pfpInfo
        }
        return false
    }
    
    func isPFPInfosChanged(_ pfpInfoArray: [DomainPFPInfo], in domains: [DomainDisplayInfo]) -> Bool {
        pfpInfoArray.first(where: { isPFPInfoChanged($0, in: domains) }) != nil
    }
}

// MARK: - Load balance
private extension WalletsDataService {
    func refreshWalletBalancesAsync(_ wallet: WalletEntity) {
        Task {
            await refreshWalletBalancesAsync(wallet)
        }
    }
    
    func refreshWalletBalancesAsync(_ wallet: WalletEntity) async {
        do {
            async let walletBalanceTask = loadEssentialBalanceFor(wallet: wallet)
            async let additionalBalancesTask = loadAdditionalBalancesFor(wallet: wallet)
            
            let (walletBalance, additionalBalances) = try await (walletBalanceTask, additionalBalancesTask)
            let allBalances = walletBalance + additionalBalances
            
            mutateWalletEntity(wallet) { wallet in
                wallet.updateBalance(allBalances)
            }
        } catch { }
    }
    
    func loadEssentialBalanceFor(wallet: WalletEntity) async throws -> [WalletTokenPortfolio] {
        switch wallet.udWallet.type {
        case .mpc:
            let mpcMetadata = try wallet.udWallet.extractMPCMetadata()
            return try await mpcWalletsService.getBalancesFor(walletMetadata: mpcMetadata)
        default:
            return try await loadBalanceFor(walletAddress: wallet.address)
        }
    }
    
    func loadAdditionalBalancesFor(wallet: WalletEntity) async -> [WalletTokenPortfolio] {
        switch wallet.udWallet.type {
        case .mpc:
            return [] // Taken from native MPC addresses
        default:
            guard let profileDomainName = wallet.profileDomainName else { return [] }
            
            let balances = await loadAdditionalBalancesFor(domainName: profileDomainName)
            return balances
        }
    }
    
    func loadAdditionalBalancesFor(addresses: Set<String>,
                                   using cachedBalances: [WalletTokenPortfolio]) async -> [WalletTokenPortfolio] {
        var balances = [WalletTokenPortfolio]()
        
        await withTaskGroup(of: [WalletTokenPortfolio].self) { group in
            for address in addresses {
                group.addTask {
                    do {
                        let tokens = try await self.loadBalanceFor(walletAddress: address)
                        return tokens
                    } catch {
                        // Do not fail everything if one of additional tokens failed
                        return cachedBalances.filter({ $0.address == address })
                    }
                }
            }
            
            for await additionalBalances in group {
                balances.append(contentsOf: additionalBalances)
            }
        }
        
        return balances
    }
    
    func getAdditionalWalletAddressesToLoadBalanceFor(domainName: DomainName) async throws -> Set<String> {
        let records = try await networkService.fetchProfileRecordsFor(domainName: domainName)
        let additionalAddresses = Set(Constants.additionalSupportedTokens.compactMap({ records[$0] }))
        
        return additionalAddresses
    }
}

// MARK: - Load NFTs
private extension WalletsDataService {
    func refreshWalletNFTsAsync(_ wallet: WalletEntity) {
        Task {
            await refreshWalletNFTsSync(wallet)
        }
    }
    
    func refreshWalletNFTsSync(_ wallet: WalletEntity) async {
        do {
            let nfts = try await loadNFTsFor(wallet: wallet)
            mutateWalletEntity(wallet) { wallet in
                wallet.nfts = nfts
            }
        } catch { }
    }
    
    func loadNFTsFor(wallet: WalletEntity) async throws -> [NFTDisplayInfo] {
        try await walletNFTsService.fetchNFTsFor(walletAddress: wallet.address).map { NFTDisplayInfo(nftModel: $0) }
    }
}

// MARK: - Setup methods
private extension WalletsDataService {
    func ensureConsistencyWithUDWallets() {
        let udWallets = getUDWallets()
        
        /// Check removed wallets
        var wallets = wallets.filter { walletEntity in
            udWallets.first(where: { $0.address == walletEntity.address }) != nil
        }
        
        /// Add or update wallets
        var newWallets: [WalletEntity] = []
        for udWallet in udWallets {
            if let i = wallets.firstIndex(where: { $0.address == udWallet.address }) {
                wallets[i].udWalletUpdated(udWallet)
            } else if let newWallet = createNewWalletEntityFor(udWallet: udWallet) {
                wallets.append(newWallet)
                newWallets.append(newWallet)
            }
        }
        
        storage.cacheWallets(wallets)
        self.wallets = wallets
        newWallets.forEach { wallet in
            refreshDataForWalletAsync(wallet)
            if wallet.udWallet.type == .mpc {
                Task.detached {
                    _ = try? await appContext.messagingService.createUserMessagingProfile(for: wallet)
                }
            }
        }
    }
    
    func createNewWalletEntityFor(udWallet: UDWallet) -> WalletEntity? {
        guard let displayInfo = WalletDisplayInfo(wallet: udWallet, domainsCount: 0, udDomainsCount: 0) else { return nil }
        
        return WalletEntity(udWallet: udWallet,
                            displayInfo: displayInfo,
                            domains: [],
                            nfts: [],
                            balance: [],
                            rrDomain: nil)
    }
}

// MARK: - Private methods
private extension WalletsDataService {
    @MainActor
    func stopRefreshDomainsTimer() {
        refreshDomainsTimer?.cancel()
        refreshDomainsTimer = nil
    }
    
    @MainActor
    func startRefreshDomainsTimer() {
        stopRefreshDomainsTimer()
        refreshDomainsTimer = Timer
            .publish(every: Constants.updateInterval, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshDomainsForCurrentWalletNonBlocking()
            }
    }
    
    @MainActor
    func refreshDomainsForCurrentWalletNonBlocking() {
        guard let selectedWallet else {
            stopRefreshDomainsTimer()
            return
        }
        
        refreshWalletDomainsNonBlocking(selectedWallet, shouldRefreshPFP: false)
    }
    
    func startRefreshDomainsTimerIfNeeded() {
        guard let selectedWallet else { return }
        
        Task {
            if isNeedToStartRefreshTimerFor(wallet: selectedWallet) {
                await startRefreshDomainsTimer()
            }
        }
    }
    
    func isNeedToStartRefreshTimerFor(wallet: WalletEntity) -> Bool {
        let domains = wallet.domains
        
        if domains.first(where: { $0.state == .minting || $0.state == .transfer }) != nil {
            return true
        }
        return false
    }
}

// MARK: - Private methods
private extension WalletsDataService {
    enum WalletsDataServiceError: String, LocalizedError {
        case walletNotFound
    }
}
