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
    private let numberOfDomainsToLoadPerTime = 30
    
    private(set) var wallets: [WalletEntity] = []
    @Published private(set) var selectedWallet: WalletEntity? = nil
    var selectedWalletPublisher: Published<WalletEntity?>.Publisher { $selectedWallet }
    
    init(domainsService: UDDomainsServiceProtocol,
         walletsService: UDWalletsServiceProtocol,
         transactionsService: DomainTransactionsServiceProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol,
         walletNFTsService: WalletNFTsServiceProtocol) {
        self.domainsService = domainsService
        self.walletsService = walletsService
        self.transactionsService = transactionsService
        self.walletConnectServiceV2 = walletConnectServiceV2
        self.walletNFTsService = walletNFTsService
        wallets = storage.getCachedWallets()
        queue.async {
            self.ensureConsistencyWithUDWallets()
            self.setCachedSelectedWalletAndRefresh()
        }
    }
    
}

// MARK: - WalletsDataServiceProtocol
extension WalletsDataService: WalletsDataServiceProtocol {
    func setSelectedWallet(_ wallet: WalletEntity) {
        selectedWallet = wallet
        refreshDataForWalletAsync(wallet)
        UserDefaults.selectedWalletAddress = wallet.address
    }
}

// MARK: - UDWalletsServiceListener
extension WalletsDataService: UDWalletsServiceListener {
    func walletsDataUpdated(notification: UDWalletsServiceNotification) {
        Task {
            switch notification {
            case .walletsUpdated, .walletRemoved:
                udWalletsUpdated()
            case .reverseResolutionDomainChanged(let domainName, _):
                if let selectedWallet,
                   selectedWallet.domains.first(where: { $0.name == domainName }) != nil {
                    refreshWalletDomainsAsync(selectedWallet, shouldRefreshPFP: false)
                }
            }
        }
    }
    
    private func udWalletsUpdated() {
        ensureConsistencyWithUDWallets()
        
        if self.wallets.first(where: { $0.address == selectedWallet?.address }) == nil {
            if self.wallets.isEmpty {
                UserDefaults.selectedWalletAddress = nil
                selectedWallet = nil
            } else {
                setSelectedWallet(self.wallets.first!)
            }
        }
    }
}

// MARK: - Private methods
private extension WalletsDataService {
    func refreshDataForWalletAsync(_ wallet: WalletEntity) {
        refreshWalletDomainsAsync(wallet, shouldRefreshPFP: true)
        refreshWalletBalancesAsync(wallet)
        refreshWalletNFTsAsync(wallet)
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
    func refreshWalletDomainsAsync(_ wallet: WalletEntity, shouldRefreshPFP: Bool) {
        Task {
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
                        wallet.domains = []
                        wallet.rrDomain = nil
                    }
                    return
                }
               
                async let transactionsTask = transactionsService.updatePendingTransactionsListFor(domains: domains.map({ $0.name }) + mintingDomainsNames)
                async let domainsPFPInfoTask = loadDomainsPFPIfNotTooLarge(domains)
                let (transactions, domainsPFPInfo) = try await (transactionsTask, domainsPFPInfoTask)
                
                let finalDomains = await buildWalletDomainsDisplayInfoData(wallet: wallet,
                                                                           domains: domains,
                                                                           pfpInfo: domainsPFPInfo,
                                                                           withTransactions: transactions,
                                                                           reverseResolutionDomainName: reverseResolutionDomainName)
                
                walletConnectServiceV2.disconnectAppsForAbsentDomains(from: finalDomains.map({ $0.domain }))
           
                if shouldRefreshPFP {
                    await loadWalletDomainsPFPIfTooLarge(wallet)
                }
            }
        }
    }
    
    func buildWalletDomainsDisplayInfoData(wallet: WalletEntity,
                                           domains: [DomainItem],
                                           pfpInfo: [DomainPFPInfo],
                                           withTransactions transactions: [TransactionItem],
                                           reverseResolutionDomainName: DomainName?) async -> [DomainWithDisplayInfo] {
        
        let pendingProfiles = PurchasedDomainsStorage.retrievePendingProfiles()
        
        // Aggregate domain display info
        var domainsWithDisplayInfo = [DomainWithDisplayInfo]()
        for domain in domains {
            var domainState: DomainDisplayInfo.State = .default
            if transactions.filterPending(extraCondition: { $0.operation == .transferDomain }).first(where: { $0.domainName == domain.name }) != nil {
                domainState = .transfer
            } else if transactions.containMintingInProgress(domain) {
                domainState = .minting
            } else if transactions.containPending(domain) {
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
        let mintingTransactions = transactions.filterPending(extraCondition: { $0.isMintingTransaction() })
        let mintingDomainsNames = mintingTransactions.compactMap({ $0.domainName })
        var mintingDomainsWithDisplayInfoItems = [DomainWithDisplayInfo]()
        
        func detectMintingDomains() -> [MintingDomain] {
            let mintingStoredDomains = MintingDomainsStorage.retrieveMintingDomains().filter({ $0.walletAddress == wallet.address })
            let mintingDomains: [MintingDomain] = mintingDomainsNames.compactMap({ (_ domainName: String) -> MintingDomain? in
                guard let mintingDomain = mintingStoredDomains.first(where: { $0.name == domainName }) else { return nil }
                
                return MintingDomain(name: domainName,
                                     walletAddress: mintingDomain.walletAddress,
                                     isPrimary: false,
                                     transactionHash: mintingDomain.transactionHash)
            })
            return mintingDomains
        }
        
        if !mintingDomainsNames.isEmpty {
            let mintingDomains = detectMintingDomains()
            mintingDomainsWithDisplayInfoItems = mintingDomains.map({
                let domainName = $0.name
                let domain = DomainItem(name: domainName,
                                        ownerWallet: $0.walletAddress,
                                        transactionHashes: [$0.transactionHash ?? ""])
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
            
            domainsWithDisplayInfo.remove(domains: mintingDomainsWithDisplayInfoItems)
            try? MintingDomainsStorage.save(mintingDomains: mintingDomains)
        } else {
            MintingDomainsStorage.clearMintingDomains()
        }
        
        let finalDomainsWithDisplayInfo = domainsWithDisplayInfo + mintingDomainsWithDisplayInfoItems
        
        mutateWalletEntity(wallet) { wallet in
            wallet.domains = finalDomainsWithDisplayInfo.map { $0.displayInfo }
            wallet.rrDomain = finalDomainsWithDisplayInfo.first(where: { $0.displayInfo.isSetForRR })?.displayInfo
        }
        
        return finalDomainsWithDisplayInfo
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
    
    func loadDomainsPFPIfNotTooLarge(_ domains: [DomainItem]) async throws -> [DomainPFPInfo] {
        if domains.count <= numberOfDomainsToLoadPerTime {
            return await domainsService.updateDomainsPFPInfo(for: domains)
        }
        return domainsService.getCachedDomainsPFPInfo()
    }
    
    func loadWalletDomainsPFPIfTooLarge(_ wallet: WalletEntity) async {
        let walletDomains = wallet.domains
        
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
                            if let i = domains.firstIndex(where: { $0.name == pfpInfo.domainName }),
                               domains[i].domainPFPInfo != pfpInfo {
                                domains[i].setPFPInfo(pfpInfo)
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

// MARK: - Load balance temp
private extension WalletsDataService {
    func refreshWalletBalancesAsync(_ wallet: WalletEntity) {
        Task {
            do {
                let walletBalances = try await loadBalanceFor(wallet: wallet)
                mutateWalletEntity(wallet) { wallet in
                    wallet.balance = walletBalances ?? []
                }
            }
        }
    }
    
    func loadBalanceFor(wallet: WalletEntity) async throws -> [WalletTokenPortfolio]? {
         try await NetworkService().fetchCryptoPortfolioFor(wallet: wallet.address)
    }
}

// MARK: - Load NFTs temp
private extension WalletsDataService {
    func refreshWalletNFTsAsync(_ wallet: WalletEntity) {
        Task {
            do {
                let nfts = try await loadNFTsFor(wallet: wallet)
                mutateWalletEntity(wallet) { wallet in
                    wallet.nfts = nfts
                }
            }
        }
    }
    
    func loadNFTsFor(wallet: WalletEntity) async throws -> [NFTDisplayInfo] {
        // TODO: - Load NFTs per wallet

        if let rrDomain = wallet.rrDomain {
            return try await fetchNFTsFor(domainName: rrDomain.name)
        } else if let domain = wallet.domains.first {
            return try await fetchNFTsFor(domainName: domain.name)
        }
        
        let domains = try await domainsService.updateDomainsList(for: [wallet.udWallet])
        if let domain = domains.first {
            return try await fetchNFTsFor(domainName: domain.name)
        }
        return []
    }
    
    func fetchNFTsFor(domainName: String) async throws -> [NFTDisplayInfo] {
        try await walletNFTsService.refreshNFTsFor(domainName: domainName).clearingInvalidNFTs().map { NFTDisplayInfo(nftModel: $0) }
    }
}

// MARK: - Setup methods
private extension WalletsDataService {
    func setCachedSelectedWalletAndRefresh() {
        selectedWallet = wallets.first(where: { $0.address == UserDefaults.selectedWalletAddress }) ?? wallets.first
        if let selectedWallet {
            refreshDataForWalletAsync(selectedWallet)
        }
        for wallet in wallets where wallet.address != selectedWallet?.address {
            refreshDataForWalletAsync(wallet)
        }
    }
    
    func ensureConsistencyWithUDWallets() {
        let udWallets = getUDWallets()
        
        /// Check removed wallets
        let removedWallets = wallets.filter { walletEntity in
            udWallets.first(where: { $0.address == walletEntity.address }) == nil
        }
        if !removedWallets.isEmpty {
            wallets = wallets.filter { walletEntity in
                removedWallets.first(where: { $0.address == walletEntity.address }) != nil
            }
        }
        
        /// Check missing wallets
        let missingWallets = udWallets.filter { udWallet in
            wallets.first(where: { $0.address == udWallet.address }) == nil
        }
        if !missingWallets.isEmpty {
            let newWallets = missingWallets.compactMap { createNewWalletEntityFor(udWallet: $0) }
            wallets.append(contentsOf: newWallets)
        }
        
        let needToUpdateCache = !removedWallets.isEmpty || !missingWallets.isEmpty
        if needToUpdateCache {
            storage.cacheWallets(wallets)
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
