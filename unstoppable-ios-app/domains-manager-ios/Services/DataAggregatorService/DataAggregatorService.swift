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
        dataHolder = DataHolder(wallets: walletsService.getUserWallets(), domains: [])
        walletsService.addListener(self)
        Task {
            await startRefreshTimer()
        }
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
        let domains = await getDomains()
        let reverseResolutionDomain = await reverseResolutionDomain(for: wallet)
        return WalletDisplayInfo(wallet: wallet,
                                 domainsCount: domains.filter( { wallet.owns(domain: $0) } ).count,
                                 reverseResolutionDomain: reverseResolutionDomain)
    }
     
    func getDomains() async -> [DomainItem] {
        let currentDomains = await dataHolder.domains
         guard currentDomains.isEmpty else {
            return currentDomains
        }
        await fillDomainsDataFromCache()
        return await dataHolder.domains
    }
    
    private func fillDomainsDataFromCache() async {
        let wallets = await getWallets()
        let cachedDomains = domainsService.getCachedDomainsFor(wallets: wallets)
        let domainNames = cachedDomains.map({ $0.name }) + (MintingDomainsStorage.retrieveMintingDomains().map({ $0.name }))
        let transactions = transactionsService.getCachedTransactionsFor(domainNames: domainNames)
        let cachedReverseResolutionMap = ReverseResolutionInfoMapStorage.retrieveReverseResolutionMap()
        await updateDataWith(domains: cachedDomains,
                             withTransactions: transactions,
                             reverseResolutionMap: cachedReverseResolutionMap)
        await prepareDomains()
    }
    
    func getReverseResolutionDomain(for walletAddress: HexAddress) async -> String? {
        return await dataHolder.reverseResolutionDomainName(for: walletAddress)
    }
    
    func setPrimaryDomainWith(name: String) async {
        UserDefaults.primaryDomainName = name
        await prepareDomains()
        let domains = await dataHolder.domains
        notifyListenersWith(result: .success(.domainsUpdated(domains)))
        notifyListenersWith(result: .success(.primaryDomainChanged(name)))
    }
    
    private func findFirstPendingRRTransaction(from txs: [TransactionItem]) -> TransactionItem? {
        txs.filterPending(extraCondition: {$0.operation == .setReverseResolution})
            .first
    }
    
    func reverseResolutionDomain(for wallet: UDWallet) async -> DomainItem? {
        let domains = await getDomains()
        let walletDomains = domains.filter({ wallet.owns(domain: $0) })
        let transactions = transactionsService.getCachedTransactionsFor(domainNames: walletDomains.map({ $0.name }))
        
        if let setRRTransaction = findFirstPendingRRTransaction(from: transactions),
           let domainName = setRRTransaction.domainName,
           let domain = domains.first(where: { $0.name == domainName }) {
            return domain
        }
        
        guard let domainName = await dataHolder.reverseResolutionDomainName(for: wallet.address) else { return nil }
        guard let domain = domains.first(where: { $0.name == domainName }) else {
            Debugger.printFailure("Failed to find domain set for Reverse Resolution", critical: false)
            return nil
        }
        
        return domain
    }
    
    func isReverseResolutionSetupInProgress(for domainName: DomainName) async -> Bool {
        let transactions = transactionsService.getCachedTransactionsFor(domainNames: [domainName])
        
        return findFirstPendingRRTransaction(from: transactions) != nil
    }
    
    func isReverseResolutionChangeAllowed(for wallet: UDWallet) async -> Bool {
        let domains = await getDomains()
        let domainNames = domains.map({ $0.name })
        let transactions = transactionsService.getCachedTransactionsFor(domainNames: domainNames)
        
        /// Restrict to change RR if any domain within wallet already changing RR.
        if !transactions.filterPending(extraCondition: {$0.operation == .setReverseResolution || $0.operation == .removeReverseResolution})
                        .isEmpty { return false }
        
        let rrDomain = await reverseResolutionDomain(for: wallet)
        let domainsAllowedToSetRR = domains.filter({ $0.name != rrDomain?.name && $0.isReverseResolutionChangeAllowed() })
        
        return !domainsAllowedToSetRR.isEmpty
    }
    
    func isReverseResolutionChangeAllowed(for domain: DomainItem) async -> Bool {
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
        let reverseResolutionMap = await dataHolder.reverseResolutionMap
        
        return reverseResolutionMap.first(where: { $0.value == domainName }) != nil
    }
    
    func aggregateData() async {
        await reloadAndAggregateData()
    }
    
    func mintDomains(_ domains: [String],
                     paidDomains: [String],
                     newPrimaryDomain: String?,
                     to wallet: UDWallet,
                     userEmail: String,
                     securityCode: String) async throws -> [MintingDomain] {
        do {
            await stopRefreshTimer()
            let transactions = try await domainsService.mintDomains(domains,
                                                                    paidDomains: paidDomains,
                                                                    to: wallet,
                                                                    userEmail: userEmail,
                                                                    securityCode: securityCode)
            transactionsService.cacheTransactions(transactions)
            let mintingDomains = domains.compactMap({ (domainName: String) -> MintingDomain?  in
                guard let foundTx = transactions.first(where: { $0.domainName == domainName }),
                      let txId = foundTx.id else { return nil }
                return MintingDomain(name: domainName,
                                     walletAddress: wallet.address,
                                     isPrimary: domainName == newPrimaryDomain,
                                     transactionId: txId,
                                     transactionHash: nil) })
            
            var currentMintingDomains = MintingDomainsStorage.retrieveMintingDomains()
            currentMintingDomains.append(contentsOf: mintingDomains)
            try MintingDomainsStorage.save(mintingDomains: currentMintingDomains)
            await reloadAndAggregateData(shouldRefreshPFP: false)
            await startRefreshTimer()
            if let primaryDomain = newPrimaryDomain {
                await setPrimaryDomainWith(name: primaryDomain)
            }
            return mintingDomains
        } catch {
            await startRefreshTimer()
            throw error
        }
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
            case .reverseResolutionDomainChanged(let domainName, let txId):
                var transactions = transactionsService.getCachedTransactionsFor(domainNames: [domainName])
                let newTransaction = TransactionItem(id: txId,
                                                     transactionHash: nil,
                                                     domainName: domainName,
                                                     isPending: true,
                                                     operation: .setReverseResolution)
                transactions.append(newTransaction)
                transactionsService.cacheTransactions(transactions)
                
                let walletsInfo = await getWalletsWithInfo()
                notifyListenersWith(result: .success(.walletsListUpdated(walletsInfo)))
                
                await dataHolder.setReverseResolutionInProgress(for: domainName)
                let domains = await getDomains()
                notifyListenersWith(result: .success(.domainsUpdated(domains)))
                AppReviewService.shared.appReviewEventDidOccurs(event: .didSetRR)
            }
        }
    }
}

// MARK: - Private methods
private extension DataAggregatorService {
    @objc func refreshData() {
        Task {
            await reloadAndAggregateData()
        }
    }
    
    func reloadAndAggregateData(shouldRefreshPFP: Bool = true) async {
        loadDomainsPFPTask?.cancel()
        await stopRefreshTimer()
        do {
            Debugger.printInfo("Will reload and aggregate data")
            let startTime = Date()
            async let domainsTask = domainsService.updateDomainsList(for: dataHolder.wallets)
            async let reverseResolutionTask = fetchIntoCacheReverseResolutionInfo()
            
            let (domains, reverseResolutionMap) = try await (domainsTask, reverseResolutionTask)

            guard !domains.isEmpty else {
                await dataHolder.setDataWith(domains: [],
                                             reverseResolutionMap: reverseResolutionMap)
                notifyListenersWith(result: .success(.domainsUpdated([])))
                let wallets = await getWalletsWithInfo()
                notifyListenersWith(result: .success(.walletsListUpdated(wallets)))
                return
            }
            
            let mintingDomainsNames = MintingDomainsStorage.retrieveMintingDomains().map({ $0.name })
            var transactions: [TransactionItem] = []
            do {
                let newTransactions = try await transactionsService.updateTransactionsListFor(domains: domains.map({ $0.name }) + mintingDomainsNames)
                transactions = newTransactions
            } catch {
                Debugger.printFailure("Failed to load transactions for \(domains.count) domains with error: \(error.localizedDescription)", critical: false)
            }
            
            let domainsWithPFP = try await loadDomainsPFPIfNotTooLarge(domains)
            await updateDataWith(domains: domainsWithPFP,
                                 withTransactions: transactions,
                                 reverseResolutionMap: reverseResolutionMap)
            await prepareDomains()
            
            let finalDomains = await dataHolder.domains
            notifyListenersWith(result: .success(.domainsUpdated(finalDomains)))
            
            let wallets = await getWalletsWithInfo()
            notifyListenersWith(result: .success(.walletsListUpdated(wallets)))
            
            walletConnectServiceV2.disconnectAppsForAbsentDomains(from: finalDomains)
            Debugger.printWarning("Did aggregate data for \(finalDomains.count) domains for \(Date().timeIntervalSince(startTime))")
            if shouldRefreshPFP {
                await loadDomainsPFPIfTooLarge()
                Debugger.printWarning("Did aggregate data with PFP for \(finalDomains.count) domains for \(Date().timeIntervalSince(startTime))")
            }
        } catch NetworkLayerError.connectionLost {
            return // May occur when user navigate between apps and underlaying requests were cancelled
        } catch {
            let error = error
            Debugger.printFailure(error.localizedDescription, critical: false)
            notifyListenersWith(result: .failure(error))
        }
        await startRefreshTimer()
    }
        
    func loadDomainsPFPIfNotTooLarge(_ domains: [DomainItem]) async throws -> [DomainItem] {
        if domains.count <= numberOfDomainsToLoadPerTime {
            return try await domainsService.updatePFP(for: domains)
        }
        return domains
    }
    
    func loadDomainsPFPIfTooLarge() async {
        let domains = await dataHolder.domains
        if domains.count > numberOfDomainsToLoadPerTime {
            let walletsWithInfo = await getWalletsWithInfo()
            let reverseResolutionDomainNames = Set(walletsWithInfo.compactMap({ $0.displayInfo?.reverseResolutionDomain?.name }))
            let loadDomainsPFPTask = Task {
                var domains = domains.sorted { lhs, rhs in
                    if lhs.isPrimary {
                        return true
                    } else if rhs.isPrimary {
                        return false
                    } else if reverseResolutionDomainNames.contains(lhs.name) {
                        return true
                    } else if reverseResolutionDomainNames.contains(rhs.name) {
                        return false
                    }
                    return false
                }
                
                while !domains.isEmpty {
                    let batch = Array(domains.prefix(numberOfDomainsToLoadPerTime))
                    if let domainsWithPFP = try? await domainsService.updatePFP(for: batch) {
                        if batch.sortedByName() != domainsWithPFP.sortedByName() {
                            await dataHolder.replaceDomains(domainsWithPFP)
                            let updatedDomains = await dataHolder.domains
                            notifyListenersWith(result: .success(.domainsPFPUpdated(updatedDomains)))
                        }
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
        
        await withTaskGroup(of: WalletWithRRDomain.self, body: { group in
            /// 1. Fill group with tasks
            for wallet in wallets {
                group.addTask {
                    /// Note: This block capturing self.
                    let domainName = await self.walletsService.reverseResolutionDomainName(for: wallet)
                    let walletWithRRDomain = WalletWithRRDomain(walletAddress: wallet.address,
                                                              domainName: domainName)
                    return walletWithRRDomain
                }
            }
            
            /// 2. Take values from group
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
    
    func prepareDomains() async {
        await dataHolder.prepareDomains(primaryDomainName: UserDefaults.primaryDomainName)
    }
    
    func updateDataWith(domains: [DomainItem],
                        withTransactions transactions: [TransactionItem],
                        reverseResolutionMap: ReverseResolutionInfoMap) async {
        
        func detectMintingDomains(in wallets: [UDWallet]) -> [MintingDomain] {
            let walletsAddresses = Set(wallets.map({ $0.address }))

            let mintingDomains: [MintingDomain] = mintingDomainsNames.compactMap({ (_ domainName: String) -> MintingDomain? in
                guard let mintingDomain = MintingDomainsStorage.retrieveMintingDomains()
                    .first(where: { $0.name == domainName }) else { return nil }
                guard walletsAddresses.contains(mintingDomain.walletAddress) else { return nil }

                return MintingDomain(name: domainName,
                                     walletAddress: mintingDomain.walletAddress,
                                     isPrimary: domainName == UserDefaults.primaryDomainName,
                                     transactionId: mintingDomain.transactionId,
                                     transactionHash: mintingDomain.transactionHash)
            })
            return mintingDomains
        }
        
        // Set isUpdatingRecord status
        var domains = domains
        for i in 0..<domains.count {
            domains[i].isUpdatingRecords = transactions.containPending(domains[i])
        }
        
        // Set minting domains
        let mintingTransactions = transactions.filterPending(extraCondition: { $0.isMintingTransaction() })
        let mintingDomainsNames = mintingTransactions.compactMap({ $0.domainName })
        var mintingDomainItems = [DomainItem]()
        
        if !mintingDomainsNames.isEmpty {
            let wallets = await dataHolder.wallets
            let mintingDomains = detectMintingDomains(in: wallets)
            mintingDomainItems = mintingDomains.map({ DomainItem(name: $0.name,
                                                                 ownerWallet: $0.walletAddress,
                                                                 transactionHashes: [$0.transactionHash ?? ""],
                                                                 isPrimary: $0.isPrimary,
                                                                 isMinting: true) })
            domains.remove(domains: mintingDomainItems)
            try? MintingDomainsStorage.save(mintingDomains: mintingDomains)
        } else {
            MintingDomainsStorage.clearMintingDomains()
        }
        
        let finalDomains = domains + mintingDomainItems
        
        await dataHolder.setDataWith(domains: finalDomains,
                                     reverseResolutionMap: reverseResolutionMap)
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
        Debugger.printInfo("Will startRefreshTimer")
        refreshTimer = Timer.scheduledTimer(timeInterval: Constants.updateInterval,
                                            target: self,
                                            selector: #selector(refreshData),
                                            userInfo: nil,
                                            repeats: false)
    }
    
    @MainActor
    func stopRefreshTimer() {
        Debugger.printInfo("Will stopRefreshTimer")
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
        var domains: [DomainItem]
        var wallets: [UDWallet]
        var reverseResolutionMap: ReverseResolutionInfoMap = [:]

        init(wallets: [UDWallet], domains: [DomainItem]) {
            self.wallets = wallets
            self.domains = domains
        }
        
        func setWallets(_ wallets: [UDWallet]) {
            self.wallets = wallets
        }
        
        func setDataWith(domains: [DomainItem],
                         reverseResolutionMap: ReverseResolutionInfoMap) {
            self.domains = domains
            self.reverseResolutionMap = reverseResolutionMap
        }
        
        func setReverseResolutionInProgress(for domainName: String) {
            if let i = domains.firstIndex(where: { $0.name == domainName }) {
                domains[i].isUpdatingRecords = true
            }
        }
        
        func appendDomains(_ domains: [DomainItem]) {
            self.domains.append(contentsOf: domains)
        }
        
        func reverseResolutionDomainName(for walletAddress: HexAddress) -> DomainName? {
            reverseResolutionMap[walletAddress] ?? nil
        }
        
        func prepareDomains(primaryDomainName: String?) {
            self.domains = domains.sorted(by: { $0.name < $1.name })
            for i in 0..<domains.count {
                domains[i].isPrimary = domains[i].name == primaryDomainName
            }
        }
        
        func replaceDomains(_ domainsToReplace: [DomainItem]) {
            for domainToReplace in domainsToReplace {
                if let i = domains.firstIndex(where: { $0.name == domainToReplace.name }) {
                    domains[i] = domainToReplace
                }
            }
        }
    }
}
