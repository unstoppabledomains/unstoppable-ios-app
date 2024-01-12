//
//  DataAggregatorService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.05.2022.
//

import Foundation

final class DataAggregatorService {
    
    typealias ReverseResolutionInfoMap = [HexAddress : DomainName?]
    
    private let domainsService: UDDomainsServiceProtocol
    private let walletsService: UDWalletsServiceProtocol
    private let transactionsService: DomainTransactionsServiceProtocol
    private let walletConnectServiceV2: WalletConnectServiceV2Protocol
    private var listeners: [DataAggregatorListenerHolder] = []
    private var refreshTimer: Timer?
    private let dataHolder: DataHolder
    private let numberOfDomainsToLoadPerTime = 30
    private var loadDomainsPFPTask: Task<Void, Never>?
    
    init(domainsService: UDDomainsServiceProtocol,
         walletsService: UDWalletsServiceProtocol,
         transactionsService: DomainTransactionsServiceProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol) {
        self.domainsService = domainsService
        self.walletsService = walletsService
        self.transactionsService = transactionsService
        self.walletConnectServiceV2 = walletConnectServiceV2
        dataHolder = DataHolder(wallets: walletsService.getUserWallets())
        walletsService.addListener(self)
        Task {
            await startRefreshTimer()
        }
    }
    
    func domainItems(from displayInfo: [DomainWithDisplayInfo]) -> [DomainDisplayInfo] {
        displayInfo.map({ $0.displayInfo })
    }
}

// MARK: - DataAggregatorServiceProtocol
extension DataAggregatorService: DataAggregatorServiceProtocol {
    func getWalletsWithInfo() async -> [WalletWithInfo] {
        let wallets = await getWallets()
        return await wallets.asyncMap({ await WalletWithInfo(wallet: $0, displayInfo: getWalletDisplayInfo(for: $0)) })
    }
    
    func getWalletsWithInfoAndBalance(for blockchainType: BlockchainType) async throws -> [WalletWithInfoAndBalance] {
        let walletsWithInfo = await getWalletsWithInfo()
        var balances = [WalletBalance]()
        
        try await withThrowingTaskGroup(of: WalletBalance.self, body: { [unowned self] group in
            /// 1. Fill group with tasks
            for wallet in walletsWithInfo {
                group.addTask {
                    /// Note: This block capturing self.
                    return try await self.walletsService.getBalanceFor(walletAddress: wallet.wallet.address, blockchainType: blockchainType, forceRefresh: false)
                }
            }
            
            /// 2. Take values from group
            for try await balance in group {
                balances.append(balance)
            }
        })
        
        var walletsWithInfoAndBalance = [WalletWithInfoAndBalance]()
        
        for walletWithInfo in walletsWithInfo {
            guard let balance = balances.first(where: { $0.address == walletWithInfo.wallet.address }) else {
                Debugger.printFailure("Failed to get balance for wallet and error wasn't thrown", critical: true)
                throw WalletError.unsupportedBlockchainType
            }
            let walletWithInfoAndBalance = WalletWithInfoAndBalance(wallet: walletWithInfo.wallet, displayInfo: walletWithInfo.displayInfo, balance: balance)
            walletsWithInfoAndBalance.append(walletWithInfoAndBalance)
        }
        
        return walletsWithInfoAndBalance
    }
  
    func getWalletDisplayInfo(for wallet: UDWallet) async -> WalletDisplayInfo? {
        let domains = await getDomainsDisplayInfo()
        let reverseResolutionDomain = await reverseResolutionDomain(for: wallet)
        let walletDomains = domains.filter { wallet.owns(domain: $0) }
        return WalletDisplayInfo(wallet: wallet,
                                 domainsCount: walletDomains.count,
                                 udDomainsCount: walletDomains.filter { $0.isUDDomain }.count,
                                 reverseResolutionDomain: reverseResolutionDomain)
    }
    
    func getDomainItems() async -> [DomainItem] {
        await getDomainsWithDisplayInfo().map { $0.domain }
    }
    
    func getDomainsDisplayInfo() async -> [DomainDisplayInfo] {
        await getDomainsWithDisplayInfo().map { $0.displayInfo }
    }

    func getDomainWith(name: String) async throws -> DomainItem {
        guard let domain = await getDomainsWith(names: [name]).first else { throw DataAggregationError.failedToFindDomain }
        
        return domain
    }
    
    func getDomainsWith(names: Set<String>) async -> [DomainItem] {
        let domainsWithInfo = await getDomainsWithDisplayInfo()
        let domains = Array(domainsWithInfo.lazy.filter({ names.contains($0.name) }).map({ $0.domain }))
        if domains.count != names.count {
            Debugger.printFailure("Not all domain items were found", critical: false)
        }
        
        return domains
    }
    
    func setDomainsOrder(using domains: [DomainDisplayInfo]) async {
        SortDomainsManager.shared.saveDomainsOrder(domains: domains)
        await dataHolder.setOrder(using: domains)
        let domains = await dataHolder.domainsWithDisplayInfo
        notifyListenersWith(result: .success(.domainsUpdated(domainItems(from: domains))))
    }

    func getReverseResolutionDomain(for walletAddress: HexAddress) async -> String? {
        guard let wallet = await dataHolder.wallets.first(where: { $0.address == walletAddress }) else { return nil }
        
        let displayInfo = await getWalletDisplayInfo(for: wallet)
        return displayInfo?.reverseResolutionDomain?.name
    }
    
    func reverseResolutionDomain(for wallet: UDWallet) async -> DomainDisplayInfo? {
        let domains = await getDomainsDisplayInfo()
        let walletDomains = domains.filter({ wallet.owns(domain: $0) })
        let transactions = await dataHolder.getTransactions(by: walletDomains.map({ $0.name }))
        
        if let setRRTransaction = findFirstPendingRRTransaction(from: transactions),
           let domainName = setRRTransaction.domainName,
           let domain = walletDomains.first(where: { $0.name == domainName }) {
            return domain
        } else if let removeRRTransaction = findFirstPendingTransaction(from: transactions, withOperation: .removeReverseResolution),
                  walletDomains.first(where: { $0.name == removeRRTransaction.domainName }) != nil {
            return nil
        }
        
        guard let domainName = await dataHolder.reverseResolutionDomainName(for: wallet.address) else { return nil }
        guard let domain = domains.first(where: { $0.name == domainName }) else {
            Debugger.printFailure("Failed to find domain set for Reverse Resolution", critical: false)
            return nil
        }
        
        return domain
    }
    
    func isReverseResolutionSetupInProgress(for domainName: DomainName) async -> Bool {
        let transactions = await dataHolder.getTransactions(by: [domainName])
        
        return findFirstPendingRRTransaction(from: transactions) != nil
    }
    
    private func findFirstPendingRRTransaction(from txs: [TransactionItem]) -> TransactionItem? {
        findFirstPendingTransaction(from: txs, withOperation: .setReverseResolution)
    }
    
    private func findFirstPendingTransaction(from txs: [TransactionItem], withOperation operation: TxOperation) -> TransactionItem? {
        txs.filterPending(extraCondition: {$0.operation == operation}).first
    }
    
    func isReverseResolutionChangeAllowed(for wallet: UDWallet) async -> Bool {
        let domains = await getDomainsDisplayInfo().filter { $0.isOwned(by: [wallet]) }
        let domainNames = domains.map({ $0.name })
        let transactions = await dataHolder.getTransactions(by: domainNames)
        
        /// Restrict to change RR if any domain within wallet already changing RR.
        if !transactions.filterPending(extraCondition: { $0.operation == .setReverseResolution || $0.operation == .removeReverseResolution })
                        .isEmpty { return false }
        
        let rrDomain = await reverseResolutionDomain(for: wallet)
        let domainsAllowedToSetRR = domains.filter({ $0.name != rrDomain?.name && $0.isReverseResolutionChangeAllowed() })
        
        return !domainsAllowedToSetRR.isEmpty
    }
    
    func isReverseResolutionChangeAllowed(for domain: DomainDisplayInfo) async -> Bool {
        if !domain.isReverseResolutionChangeAllowed() {
            return false
        }
        
        let wallets = await getWallets()
        guard let wallet = wallets.first(where: { $0.owns(domain: domain) }) else {
            Debugger.printFailure("Failed to find wallet for existing domain", critical: true)
            return false
        }
        
        return await isReverseResolutionChangeAllowed(for: wallet)
    }
    
    func isReverseResolutionSet(for domainName: DomainName) async -> Bool {
        let wallets = await getWalletsWithInfo()
        return wallets.first(where: { $0.displayInfo?.reverseResolutionDomain?.name == domainName }) != nil
    }
    
    func aggregateData(shouldRefreshPFP: Bool) async {
        await reloadAndAggregateData(shouldRefreshPFP: shouldRefreshPFP)
    }
    
    func mintDomains(_ domains: [String],
                     paidDomains: [String],
                     domainsOrderInfoMap: SortDomainsOrderInfoMap,
                     to wallet: UDWallet,
                     userEmail: String,
                     securityCode: String) async throws -> [MintingDomain] {
        do {
            await stopRefreshTimer()
            try await domainsService.mintDomains(domains,
                                                 paidDomains: paidDomains,
                                                 to: wallet,
                                                 userEmail: userEmail,
                                                 securityCode: securityCode)
            let transactions = domains.map { TransactionItem(id: 0,
                                                             domainName: $0,
                                                             isPending: true,
                                                             type: .maticTx,
                                                             operation: .mintDomain) }
            transactionsService.cacheTransactions(transactions)
            
            let mintingDomains = domains.map { MintingDomain(name: $0,
                                                             walletAddress: wallet.address,
                                                             isPrimary: false,
                                                             transactionHash: nil) }
            
            var currentMintingDomains = MintingDomainsStorage.retrieveMintingDomains()
            currentMintingDomains.append(contentsOf: mintingDomains)
            try MintingDomainsStorage.save(mintingDomains: currentMintingDomains)
            SortDomainsManager.shared.saveDomainsOrderMap(domainsOrderInfoMap)
            await reloadAndAggregateData(shouldRefreshPFP: false)
            await startRefreshTimer()
            
            return mintingDomains
        } catch {
            await startRefreshTimer()
            throw error
        }
    }
    
    func didPurchaseDomains(_ purchasedDomains: [PendingPurchasedDomain],
                            pendingProfiles: [DomainProfilePendingChanges]) async {
        var domainsWithDisplayInfo = await dataHolder.domainsWithDisplayInfo
        let purchasedDomainsWithDisplayInfo = await transformPendingPurchasedDomainToDomainsWithInfo(purchasedDomains,
        pendingProfiles: pendingProfiles)
        domainsWithDisplayInfo.append(contentsOf: purchasedDomainsWithDisplayInfo)
        let reverseResolutionMap = await dataHolder.reverseResolutionMap
        await dataHolder.setDataWith(domainsWithDisplayInfo: domainsWithDisplayInfo,
                                     reverseResolutionMap: reverseResolutionMap)
        notifyListenersWith(result: .success(.domainsUpdated(domainItems(from: domainsWithDisplayInfo))))
    }
    
    func addListener(_ listener: DataAggregatorServiceListener) {
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: DataAggregatorServiceListener) {
        listeners.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - UDWalletsServiceListener
extension DataAggregatorService: UDWalletsServiceListener {
    func walletsDataUpdated(notification: UDWalletsServiceNotification) {
        Task {
            switch notification {
            case .walletsUpdated(let wallets):
                let walletsCount = await self.dataHolder.wallets.count
                
                await dataHolder.setWallets(wallets)
                let walletsInfo = await getWalletsWithInfo()
                notifyListenersWith(result: .success(.walletsListUpdated(walletsInfo)))
                
                // If wallet were added/removed we'll update domains list
                if wallets.count != walletsCount {
                    await reloadAndAggregateData()
                }
                await checkAppSessionAndLogOutIfNeeded()
            case .reverseResolutionDomainChanged(let domainName, let txIds):
                var transactions = await dataHolder.getTransactions(by: [domainName])
                let newTransactions = txIds.map({TransactionItem(id: $0,
                                                                 transactionHash: nil,
                                                                 domainName: domainName,
                                                                 isPending: true,
                                                                 operation: .setReverseResolution)})
                transactions.append(contentsOf: newTransactions)
                transactionsService.cacheTransactions(transactions)
                
                let walletsInfo = await getWalletsWithInfo()
                notifyListenersWith(result: .success(.walletsListUpdated(walletsInfo)))
                
                await dataHolder.setReverseResolutionInProgress(for: domainName)
                let domains = await getDomainsDisplayInfo()
                notifyListenersWith(result: .success(.domainsUpdated(domains)))
                AppReviewService.shared.appReviewEventDidOccurs(event: .didSetRR)
            case .walletRemoved: return
            }
        }
    }
}

// MARK: - FirebaseAuthenticationServiceListener
extension DataAggregatorService: FirebaseAuthenticationServiceListener {
    func firebaseUserUpdated(firebaseUser: FirebaseUser?) {
        Task {
            if firebaseUser != nil {
                let parkedDomains = await loadParkedDomains()
                await fillDomainsDataFromCache(parkedDomains: parkedDomains)
                let updatedDomains = await dataHolder.domainsWithDisplayInfo
                notifyListenersWith(result: .success(.domainsUpdated(domainItems(from: updatedDomains))))
            }
            
            await reloadAndAggregateData(shouldRefreshPFP: false)
            await checkAppSessionAndLogOutIfNeeded()
        }
    }
}

// MARK: - Private methods
private extension DataAggregatorService {
    @MainActor
    func checkAppSessionAndLogOutIfNeeded() {
        let sessionState = AppSessionInterpreter.shared.state()
        switch sessionState {
        case .walletAdded, .webAccountWithParkedDomains:
            return
        case .noWalletsOrWebAccount, .webAccountWithoutParkedDomains:
            SceneDelegate.shared?.restartOnboarding()
            appContext.firebaseParkedDomainsAuthenticationService.logout()
            Task { await aggregateData(shouldRefreshPFP: false) }
        }
    }
    
    func getDomainsWithDisplayInfo() async -> [DomainWithDisplayInfo] {
        let currentDomains = await dataHolder.domainsWithDisplayInfo
        guard currentDomains.isEmpty else {
            return currentDomains
        }
        await fillDomainsDataFromCache()
        let domains = await dataHolder.domainsWithDisplayInfo
        return domains
    }
    
    func fillDomainsDataFromCache() async {
        let cachedParkedDomains = appContext.firebaseParkedDomainsService.getCachedDomains()
        await fillDomainsDataFromCache(parkedDomains: cachedParkedDomains)
    }
    
    func fillDomainsDataFromCache(parkedDomains: [FirebaseDomain]) async {
        let wallets = await getWallets()
        let cachedDomains = domainsService.getCachedDomainsFor(wallets: wallets)
        let domainNames = cachedDomains.map({ $0.name }) + (MintingDomainsStorage.retrieveMintingDomains().map({ $0.name }))
        let cachedTransactions = transactionsService.getCachedTransactionsFor(domainNames: domainNames)
        let cachedReverseResolutionMap = ReverseResolutionInfoMapStorage.retrieveReverseResolutionMap()
        let cachedPFPInfo = domainsService.getCachedDomainsPFPInfo()
        await buildDomainsDisplayInfoDataWith(domains: cachedDomains,
                                              pfpInfo: cachedPFPInfo,
                                              parkedDomains: parkedDomains,
                                              withTransactions: cachedTransactions,
                                              reverseResolutionMap: cachedReverseResolutionMap)
    }
    
    @objc func refreshData() {
        Task {
            await reloadAndAggregateData()
        }
    }
    
    func reloadAndAggregateData(shouldRefreshPFP: Bool = true) async {
        loadDomainsPFPTask?.cancel()
        await stopRefreshTimer()
        do {
            Debugger.printInfo(topic: .DataAggregation, "Will reload and aggregate data")
            let startTime = Date()
            async let domainsTask = domainsService.updateDomainsList(for: dataHolder.wallets)
            async let reverseResolutionTask = fetchIntoCacheReverseResolutionInfo()
            async let parkedDomainsTask = loadParkedDomains()
            
            let (domains, reverseResolutionMap, parkedDomains) = try await (domainsTask, reverseResolutionTask, parkedDomainsTask)
            let mintingDomainsNames = MintingDomainsStorage.retrieveMintingDomains().map({ $0.name })
            let pendingPurchasedDomains = getPurchasedDomainsUnlessInList(domains)
            
            guard !domains.isEmpty || !mintingDomainsNames.isEmpty || !parkedDomains.isEmpty || !pendingPurchasedDomains.isEmpty else {
                await dataHolder.setDataWith(domainsWithDisplayInfo: [],
                                             reverseResolutionMap: reverseResolutionMap)
                let wallets = await getWalletsWithInfo()
                notifyListenersWith(result: .success(.walletsListUpdated(wallets)))
                notifyListenersWith(result: .success(.domainsUpdated([])))
                return
            }
            
            var transactions: [TransactionItem] = []
            do {
                let newTransactions = try await transactionsService.updatePendingTransactionsListFor(domains: domains.map({ $0.name }) + mintingDomainsNames)
                transactions = newTransactions
            } catch {
                Debugger.printFailure("Failed to load transactions for \(domains.count) domains with error: \(error.localizedDescription)", critical: false)
            }
            
            let domainsPFPInfo = try await loadDomainsPFPIfNotTooLarge(domains)
            await buildDomainsDisplayInfoDataWith(domains: domains,
                                                  pfpInfo: domainsPFPInfo,
                                                  parkedDomains: parkedDomains,
                                                  withTransactions: transactions,
                                                  reverseResolutionMap: reverseResolutionMap)
            
            let wallets = await getWalletsWithInfo()
            notifyListenersWith(result: .success(.walletsListUpdated(wallets)))
            
            let finalDomains = await dataHolder.domainsWithDisplayInfo
            notifyListenersWith(result: .success(.domainsUpdated(domainItems(from: finalDomains))))
            
            walletConnectServiceV2.disconnectAppsForAbsentDomains(from: finalDomains.map({ $0.domain }))
            Debugger.printTimeSensitiveInfo(topic: .DataAggregation,
                                            "to aggregate data for \(finalDomains.count) domains",
                                            startDate: startTime,
                                            timeout: 3)
            if shouldRefreshPFP {
                await loadDomainsPFPIfTooLarge()
                Debugger.printTimeSensitiveInfo(topic: .DataAggregation,
                                                "to aggregate data with PFP for \(finalDomains.count) domains",
                                                startDate: startTime,
                                                timeout: 5)                
            }
        } catch NetworkLayerError.connectionLost, NetworkLayerError.requestCancelled {
            await reloadAndAggregateData(shouldRefreshPFP: shouldRefreshPFP)
            return // May occur when user navigate between apps and underlaying requests were cancelled
        } catch {
            let error = error
            Debugger.printFailure(error.localizedDescription, critical: false)
            notifyListenersWith(result: .failure(error))
        }
        await startRefreshTimer()
    }
    
    func loadParkedDomains() async -> [FirebaseDomain] {
        let domains = try? await appContext.firebaseParkedDomainsService.getParkedDomains()
        
        return domains ?? []
    }
        
    func loadDomainsPFPIfNotTooLarge(_ domains: [DomainItem]) async throws -> [DomainPFPInfo] {
        if domains.count <= numberOfDomainsToLoadPerTime {
            return await domainsService.updateDomainsPFPInfo(for: domains)
        }
        return domainsService.getCachedDomainsPFPInfo()
    }
    
    func loadDomainsPFPIfTooLarge() async {
        let domainsWithInfo = await dataHolder.domainsWithDisplayInfo
        if domainsWithInfo.count > numberOfDomainsToLoadPerTime {
            let walletsWithInfo = await getWalletsWithInfo()
            let reverseResolutionDomainNames = Set(walletsWithInfo.compactMap({ $0.displayInfo?.reverseResolutionDomain?.name }))
            let loadDomainsPFPTask = Task {
                var domains = Array(domainsWithInfo.lazy.sorted { lhs, rhs in
                    if lhs.displayInfo.isPrimary {
                        return true
                    } else if rhs.displayInfo.isPrimary {
                        return false
                    } else if reverseResolutionDomainNames.contains(lhs.name) {
                        return true
                    } else if reverseResolutionDomainNames.contains(rhs.name) {
                        return false
                    }
                    return false
                }.map({ $0.domain }))
                
                while !domains.isEmpty {
                    let batch = Array(domains.prefix(numberOfDomainsToLoadPerTime))
                    let pfpInfo = await domainsService.updateDomainsPFPInfo(for: batch)
                    let isPFPInfoChanged = await dataHolder.updateDisplayDomainsPFPInfoIfChanged(pfpInfo)
                    
                    if isPFPInfoChanged {
                        let updatedDomains = await dataHolder.domainsWithDisplayInfo
                        notifyListenersWith(result: .success(.domainsPFPUpdated(domainItems(from: updatedDomains))))
                    }
                    
                    if Task.isCancelled {
                        break
                    }
                    domains = Array(domains.dropFirst(batch.count))
                }
            }
            self.loadDomainsPFPTask = loadDomainsPFPTask
            await loadDomainsPFPTask.value
        }
    }
    
    func fetchIntoCacheReverseResolutionInfo() async -> ReverseResolutionInfoMap {
        struct WalletWithRRDomain {
            let walletAddress: HexAddress
            let domainName: DomainName?
        }
        
        let wallets = await dataHolder.wallets
        var walletsWithRRDomains = [WalletWithRRDomain]()
        let cachedRRDomainsMap = ReverseResolutionInfoMapStorage.retrieveReverseResolutionMap()
        
        await withTaskGroup(of: WalletWithRRDomain.self, body: { group in
            for wallet in wallets {
                group.addTask {
                    var domainName: String?
                    do {
                        domainName = try await self.walletsService.reverseResolutionDomainName(for: wallet)
                    } catch {
                        /// If request failed to get current RR domain, use cached value
                        if let cachedName = cachedRRDomainsMap[wallet.address] {
                            domainName = cachedName
                        }
                    }
                    let walletWithRRDomain = WalletWithRRDomain(walletAddress: wallet.address,
                                                                domainName: domainName)
                    return walletWithRRDomain
                }
            }
            
            for await walletWithRRDomain in group {
                walletsWithRRDomains.append(walletWithRRDomain)
            }
        })
        
        var reverseResolutionMap = ReverseResolutionInfoMap()
        for rrDomain in walletsWithRRDomains {
            if let domainName = rrDomain.domainName,
               !domainName.isEmpty {
                reverseResolutionMap[rrDomain.walletAddress] = domainName
            }
        }
        
        ReverseResolutionInfoMapStorage.save(reverseResolutionMap: reverseResolutionMap)
 
        return reverseResolutionMap
    }
    
    func buildDomainsDisplayInfoDataWith(domains: [DomainItem],
                                         pfpInfo: [DomainPFPInfo],
                                         parkedDomains: [FirebaseDomain],
                                         withTransactions transactions: [TransactionItem],
                                         reverseResolutionMap: ReverseResolutionInfoMap) async {
        
        let rrDomainsList = Set(reverseResolutionMap.compactMap( { $0.value } ))
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
                                                      isSetForRR: rrDomainsList.contains(domain.name))
            
            domainsWithDisplayInfo.append(.init(domain: domain,
                                                displayInfo: domainDisplayInfo))
        }
        
        // Purchased domains
        let pendingPurchasedDomains = getPurchasedDomainsUnlessInList(domains)
        let purchasedDomainsWithDisplayInfo = await transformPendingDomainItemsToDomainsWithInfo(pendingPurchasedDomains,
                                                                                                 using: pfpInfo,
                                                                                                 pendingProfiles: pendingProfiles)
        domainsWithDisplayInfo.append(contentsOf: purchasedDomainsWithDisplayInfo)
        
        // Parked domains
        for parkedDomain in parkedDomains {
            let parkedDomainDisplayInfo = FirebaseDomainDisplayInfo(firebaseDomain: parkedDomain)
            let domain = DomainItem(name: parkedDomain.name, ownerWallet: parkedDomain.ownerAddress, status: .unclaimed)
            let order = SortDomainsManager.shared.orderFor(domainName: domain.name)
            let domainDisplayInfo = DomainDisplayInfo(name: parkedDomain.name,
                                                      ownerWallet: parkedDomain.ownerAddress,
                                                      state: .parking(status: parkedDomainDisplayInfo.parkingStatus),
                                                      order: order,
                                                      isSetForRR: false)
            domainsWithDisplayInfo.append(.init(domain: domain,
                                                displayInfo: domainDisplayInfo))
        }
        
        // Set minting domains
        let mintingTransactions = transactions.filterPending(extraCondition: { $0.isMintingTransaction() })
        let mintingDomainsNames = mintingTransactions.compactMap({ $0.domainName })
        var mintingDomainsWithDisplayInfoItems = [DomainWithDisplayInfo]()

        func detectMintingDomains(in wallets: [UDWallet]) -> [MintingDomain] {
            let walletsAddresses = Set(wallets.map({ $0.address }))
            
            let mintingDomains: [MintingDomain] = mintingDomainsNames.compactMap({ (_ domainName: String) -> MintingDomain? in
                guard let mintingDomain = MintingDomainsStorage.retrieveMintingDomains()
                    .first(where: { $0.name == domainName }) else { return nil }
                guard walletsAddresses.contains(mintingDomain.walletAddress) else { return nil }
                
                return MintingDomain(name: domainName,
                                     walletAddress: mintingDomain.walletAddress,
                                     isPrimary: false,  
                                     transactionHash: mintingDomain.transactionHash)
            })
            return mintingDomains
        }
        
        if !mintingDomainsNames.isEmpty {
            let wallets = await dataHolder.wallets
            let mintingDomains = detectMintingDomains(in: wallets)
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
                                                    isSetForRR: rrDomainsList.contains(domainName))
                
                return DomainWithDisplayInfo(domain: domain, displayInfo: displayInfo)
            })
            
            domainsWithDisplayInfo.remove(domains: mintingDomainsWithDisplayInfoItems)
            try? MintingDomainsStorage.save(mintingDomains: mintingDomains)
        } else {
            MintingDomainsStorage.clearMintingDomains()
        }
        
        let finalDomainsWithDisplayInfo = domainsWithDisplayInfo + mintingDomainsWithDisplayInfoItems
        
        await dataHolder.setTransactions(transactions)
        await dataHolder.setDataWith(domainsWithDisplayInfo: finalDomainsWithDisplayInfo,
                                     reverseResolutionMap: reverseResolutionMap)
        await dataHolder.sortDomainsToDisplay()
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
    
    func resolveDomainPFPInfo(for domainName: String,
                              using pfpInfo: [DomainPFPInfo],
                              pendingProfiles: [DomainProfilePendingChanges]) async -> DomainPFPInfo? {
        if let profile = pendingProfiles.first(where: { $0.domainName == domainName }),
           let localImage = await profile.getAvatarImage() {
            return .init(domainName: domainName, localImage: localImage)
        }
        return pfpInfo.first(where: { $0.domainName == domainName })
    }
    
    func getPurchasedDomainsUnlessInList(_ domains: [DomainItem]) -> [DomainItem] {
        let pendingPurchasedDomains = PurchasedDomainsStorage.retrievePurchasedDomains().filter({ pendingDomain in
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
    
    func getWallets() async -> [UDWallet] {
        let currentWallets = await dataHolder.wallets
        if !currentWallets.isEmpty {
            return currentWallets
        }
        let wallets = walletsService.getUserWallets()
        await dataHolder.setWallets(wallets)
        return wallets
    }
}

// MARK: - Private methods
private extension DataAggregatorService {
    @MainActor
    func startRefreshTimer() {
        stopRefreshTimer()
        Debugger.printInfo(topic: .DataAggregation, "Will startRefreshTimer")
        refreshTimer = Timer.scheduledTimer(timeInterval: Constants.updateInterval,
                                            target: self,
                                            selector: #selector(refreshData),
                                            userInfo: nil,
                                            repeats: false)
    }
    
    @MainActor
    func stopRefreshTimer() {
        Debugger.printInfo(topic: .DataAggregation, "Will stopRefreshTimer")
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func notifyListenersWith(result: DataAggregationResult) {
        listeners.forEach { holder in
            holder.listener?.dataAggregatedWith(result: result)
        }
    }
}

// MARK: - Private methods
private extension DataAggregatorService {
    actor DataHolder {
        var domainsWithDisplayInfo: [DomainWithDisplayInfo] = []
        var wallets: [UDWallet]
        var reverseResolutionMap: ReverseResolutionInfoMap = [:]
        var transactions: [TransactionItem] = []

        init(wallets: [UDWallet]) {
            self.wallets = wallets
        }
        
        func setWallets(_ wallets: [UDWallet]) {
            self.wallets = wallets
        }
        
        func setTransactions(_ transactions: [TransactionItem]) {
            self.transactions = transactions
        }
        
        func getTransactions(by domainNames: [String]) -> [TransactionItem] {
            transactions.filter({
                guard let domainName = $0.domainName else { return false }
                return domainNames.contains(domainName)
            })
        }
        
        func setDataWith(domainsWithDisplayInfo: [DomainWithDisplayInfo],
                         reverseResolutionMap: ReverseResolutionInfoMap) {
            self.domainsWithDisplayInfo = domainsWithDisplayInfo
            self.reverseResolutionMap = reverseResolutionMap
        }
        
        func setReverseResolutionInProgress(for domainName: String) {
            if let i = domainsWithDisplayInfo.firstIndex(where: { $0.name == domainName }) {
                domainsWithDisplayInfo[i].displayInfo.setState(.updatingRecords)
            }
        }
        
        func reverseResolutionDomainName(for walletAddress: HexAddress) -> DomainName? {
            if let key = reverseResolutionMap.keys.first(where: { $0.lowercased() == walletAddress.lowercased() }) {
                return reverseResolutionMap[key] ?? nil
            }
            return nil
        }
        
        func sortDomainsToDisplay() {
            self.domainsWithDisplayInfo = domainsWithDisplayInfo.sorted()
        }
        
        func setOrder(using domains: [DomainDisplayInfo]) {
            for domain in domains {
                if let i = domainsWithDisplayInfo.firstIndex(where: { $0.displayInfo.isSameEntity(domain) }) {
                    domainsWithDisplayInfo[i].displayInfo.setOrder(domain.order)
                }
            }
            sortDomainsToDisplay()
        }
        
        @discardableResult
        /// Return true if pfp info was changed
        func updateDisplayDomainsPFPInfoIfChanged(_ pfpInfoArray: [DomainPFPInfo]) -> Bool {
            var isPFPInfoChanged = false
            
            for pfpInfo in pfpInfoArray {
                if let i = domainsWithDisplayInfo.firstIndex(where: { $0.name == pfpInfo.domainName }),
                   domainsWithDisplayInfo[i].displayInfo.domainPFPInfo != pfpInfo {
                    isPFPInfoChanged = true
                    domainsWithDisplayInfo[i].displayInfo.setPFPInfo(pfpInfo)
                }
            }
            
            return isPFPInfoChanged
        }
    }
}

extension DataAggregatorService {
    enum DataAggregationError: String, LocalizedError {
        case failedToFindDomain
        
        public var errorDescription: String? { rawValue }
    }
}
