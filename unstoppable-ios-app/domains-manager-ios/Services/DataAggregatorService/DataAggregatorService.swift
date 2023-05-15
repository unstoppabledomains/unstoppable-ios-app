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
        return WalletDisplayInfo(wallet: wallet,
                                 domainsCount: domains.filter( { wallet.owns(domain: $0) } ).count,
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
        await dataHolder.reverseResolutionDomainName(for: walletAddress)
    }
    
    func reverseResolutionDomain(for wallet: UDWallet) async -> DomainDisplayInfo? {
        let domains = await getDomainsDisplayInfo()
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
    
    private func findFirstPendingRRTransaction(from txs: [TransactionItem]) -> TransactionItem? {
        txs.filterPending(extraCondition: {$0.operation == .setReverseResolution})
            .first
    }
    
    func isReverseResolutionChangeAllowed(for wallet: UDWallet) async -> Bool {
        let domains = await getDomainsDisplayInfo()
        let domainNames = domains.map({ $0.name })
        let transactions = transactionsService.getCachedTransactionsFor(domainNames: domainNames)
        
        /// Restrict to change RR if any domain within wallet already changing RR.
        if !transactions.filterPending(extraCondition: {$0.operation == .setReverseResolution || $0.operation == .removeReverseResolution})
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
        let reverseResolutionMap = await dataHolder.reverseResolutionMap
        
        return reverseResolutionMap.first(where: { $0.value == domainName }) != nil
    }
    
    func aggregateData() async {
        await reloadAndAggregateData()
    }
    
    func mintDomains(_ domains: [String],
                     paidDomains: [String],
                     domainsOrderInfoMap: SortDomainsOrderInfoMap,
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
                                     isPrimary: false,
                                     transactionId: txId,
                                     transactionHash: nil) })
            
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
            case .reverseResolutionDomainChanged(let domainName, let txIds):
                var transactions = transactionsService.getCachedTransactionsFor(domainNames: [domainName])
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
            }
        }
    }
}

// MARK: - Private methods
private extension DataAggregatorService {
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
        let wallets = await getWallets()
        let cachedDomains = domainsService.getCachedDomainsFor(wallets: wallets)
        let domainNames = cachedDomains.map({ $0.name }) + (MintingDomainsStorage.retrieveMintingDomains().map({ $0.name }))
        let cachedTransactions = transactionsService.getCachedTransactionsFor(domainNames: domainNames)
        let cachedReverseResolutionMap = ReverseResolutionInfoMapStorage.retrieveReverseResolutionMap()
        let cachedPFPInfo = domainsService.getCachedDomainsPFPInfo()
        await buildDomainsDisplayInfoDataWith(domains: cachedDomains,
                                              pfpInfo: cachedPFPInfo,
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
            Debugger.printInfo("Will reload and aggregate data")
            let startTime = Date()
            async let domainsTask = domainsService.updateDomainsList(for: dataHolder.wallets)
            async let reverseResolutionTask = fetchIntoCacheReverseResolutionInfo()
            
            let (domains, reverseResolutionMap) = try await (domainsTask, reverseResolutionTask)
            let mintingDomainsNames = MintingDomainsStorage.retrieveMintingDomains().map({ $0.name })

            guard !domains.isEmpty || !mintingDomainsNames.isEmpty else {
                await dataHolder.setDataWith(domainsWithDisplayInfo: [],
                                             reverseResolutionMap: reverseResolutionMap)
                notifyListenersWith(result: .success(.domainsUpdated([])))
                let wallets = await getWalletsWithInfo()
                notifyListenersWith(result: .success(.walletsListUpdated(wallets)))
                return
            }
            
            var transactions: [TransactionItem] = []
            do {
                let newTransactions = try await transactionsService.updateTransactionsListFor(domains: domains.map({ $0.name }) + mintingDomainsNames)
                transactions = newTransactions
            } catch {
                Debugger.printFailure("Failed to load transactions for \(domains.count) domains with error: \(error.localizedDescription)", critical: false)
            }
            
            let domainsPFPInfo = try await loadDomainsPFPIfNotTooLarge(domains)
            await buildDomainsDisplayInfoDataWith(domains: domains,
                                                  pfpInfo: domainsPFPInfo,
                                                  withTransactions: transactions,
                                                  reverseResolutionMap: reverseResolutionMap)
            
            let finalDomains = await dataHolder.domainsWithDisplayInfo
            notifyListenersWith(result: .success(.domainsUpdated(domainItems(from: finalDomains))))
            
            let wallets = await getWalletsWithInfo()
            notifyListenersWith(result: .success(.walletsListUpdated(wallets)))
            walletConnectServiceV2.disconnectAppsForAbsentDomains(from: finalDomains.map({ $0.domain }))
            Debugger.printWarning("Did aggregate data for \(finalDomains.count) domains for \(Date().timeIntervalSince(startTime))")
            if shouldRefreshPFP {
                await loadDomainsPFPIfTooLarge()
                Debugger.printWarning("Did aggregate data with PFP for \(finalDomains.count) domains for \(Date().timeIntervalSince(startTime))")
            }
        } catch NetworkLayerError.connectionLost {
            await reloadAndAggregateData(shouldRefreshPFP: shouldRefreshPFP)
            return // May occur when user navigate between apps and underlaying requests were cancelled
        } catch {
            let error = error
            Debugger.printFailure(error.localizedDescription, critical: false)
            notifyListenersWith(result: .failure(error))
        }
        await startRefreshTimer()
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
    
    func buildDomainsDisplayInfoDataWith(domains: [DomainItem],
                                         pfpInfo: [DomainPFPInfo],
                                         withTransactions transactions: [TransactionItem],
                                         reverseResolutionMap: ReverseResolutionInfoMap) async {
        
        let rrDomainsList = Set(reverseResolutionMap.compactMap( { $0.value } ))
        
        // Aggregate domain display info
        var domainsWithDisplayInfo = [DomainWithDisplayInfo]()
        for domain in domains {
            let domainState: DomainDisplayInfo.State = transactions.containPending(domain) ? .updatingRecords : .default
            let domainPFPInfo = pfpInfo.first(where: { $0.domainName == domain.name })
            let order = SortDomainsManager.shared.orderFor(domainName: domain.name)
            let domainDisplayInfo = DomainDisplayInfo(domainItem: domain,
                                                      pfpInfo: domainPFPInfo,
                                                      state: domainState,
                                                      order: order,
                                                      isSetForRR: rrDomainsList.contains(domain.name))
            
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
                                     transactionId: mintingDomain.transactionId,
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
        
        await dataHolder.setDataWith(domainsWithDisplayInfo: finalDomainsWithDisplayInfo,
                                     reverseResolutionMap: reverseResolutionMap)
        await dataHolder.sortDomainsToDisplay()
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
        var domainsWithDisplayInfo: [DomainWithDisplayInfo] = []
        var wallets: [UDWallet]
        var reverseResolutionMap: ReverseResolutionInfoMap = [:]

        init(wallets: [UDWallet]) {
            self.wallets = wallets
        }
        
        func setWallets(_ wallets: [UDWallet]) {
            self.wallets = wallets
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
            reverseResolutionMap[walletAddress] ?? nil
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
    enum DataAggregationError: Error {
        case failedToFindDomain
    }
}
