//
//  MockDataAggregationService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.05.2022.
//

import Foundation

final class MockDataAggregatorService {
    private let domainsService: UDDomainsServiceProtocol
    private let walletsService: UDWalletsServiceProtocol
    private let transactionsService: DomainTransactionsServiceProtocol
    private var listeners: [DataAggregatorListenerHolder] = []
    var domainsWithDisplayInfo: [DomainWithDisplayInfo] = []

    init(domainsService: UDDomainsServiceProtocol,
         walletsService: UDWalletsServiceProtocol,
         transactionsService: DomainTransactionsServiceProtocol) {
        self.domainsService = domainsService
        self.walletsService = walletsService
        self.transactionsService = transactionsService
        walletsService.addListener(self)
    }
}

// MARK: - DataAggregatorServiceProtocol
extension MockDataAggregatorService: DataAggregatorServiceProtocol {
    func getDomainsDisplayInfo() async -> [DomainDisplayInfo] {
        if domainsWithDisplayInfo.isEmpty {
            let domains = await getCachedDomainsFor(wallets: walletsService.getUserWallets())
            for (i, domain) in domains.enumerated() {
                let displayInfo = DomainDisplayInfo(domainItem: domain,
                                                    pfpInfo: nil,
                                                    state: (i % 2 == 0) ? .minting : .default,
                                                    order: i,
                                                    isSetForRR: false)
                domainsWithDisplayInfo.append(.init(domain: domain,
                                                    displayInfo: displayInfo))
            }
            
            let mintingInProgressDomains = domainsWithDisplayInfo.filter({ $0.displayInfo.isMinting })
            if mintingInProgressDomains.isEmpty {
                MintingDomainsStorage.clearMintingDomains()
            } else {
                let mintingDomains = mintingInProgressDomains.map({ MintingDomain(name: $0.name,
                                                                                  walletAddress: $0.displayInfo.ownerWallet ?? "",
                                                                                  isPrimary: false,
                                                                                  transactionId: 0)})
                try? MintingDomainsStorage.save(mintingDomains: mintingDomains)
            }
        }
        
        return domainsWithDisplayInfo.map { $0.displayInfo }
    }
    
    func getCachedDomainsFor(wallets: [UDWallet]) async -> [DomainItem] {
        let domains = try! await domainsService.updateDomainsList(for: wallets)
        return domains
    }
    
    func getDomainWith(name: String) async throws -> DomainItem { throw NSError() }
    func getDomainsWith(names: Set<String>) async -> [DomainItem] { [] }
    func getReverseResolutionDomain(for walletAddress: HexAddress) async -> String?
    { nil }
    
    func getWalletsWithInfo() async -> [WalletWithInfo] {
        var walletsWithInfo = [WalletWithInfo]()
        
        let wallets = walletsService.getUserWallets()
        for wallet in wallets {
            let displayInfo = await getWalletDisplayInfo(for: wallet)
            let walletWithInfo = WalletWithInfo(wallet: wallet,
                                                displayInfo: displayInfo)
            walletsWithInfo.append(walletWithInfo)
        }
        
        return walletsWithInfo
    }
    
    func getWalletsWithInfoAndBalance(for blockchainType: BlockchainType) async throws -> [WalletWithInfoAndBalance] {
        var walletsWithInfo = [WalletWithInfoAndBalance]()
        
        let wallets = walletsService.getUserWallets()
        for wallet in wallets {
            let displayInfo = await getWalletDisplayInfo(for: wallet)
            let walletWithInfoAndBalance = WalletWithInfoAndBalance(wallet: wallet,
                                                                    displayInfo: displayInfo,
                                                                    balance: .init(address: wallet.address,
                                                                                   quantity: try! .init(10),
                                                                                   exchangeRate: 1,
                                                                                   blockchain: .Ethereum))
            walletsWithInfo.append(walletWithInfoAndBalance)
        }
        
        return walletsWithInfo
    }
    
    func getWalletDisplayInfo(for wallet: UDWallet) async -> WalletDisplayInfo? {
        let rrDomain = await reverseResolutionDomain(for: wallet)
        let domains = await getDomainsDisplayInfo()
        let domainsCount = domains.filter({ $0.isOwned(by: [wallet] )}).count
        return WalletDisplayInfo(wallet: wallet,
                                 domainsCount: domainsCount,
                                 udDomainsCount: domainsCount,
                                 reverseResolutionDomain: rrDomain)
        
    }
    
//    func getDomains() async -> [DomainItem] {
//
//    }
    
    
    func getDomainItems() async -> [DomainItem] {
        []
    }
    
    func setDomainsOrder(using domains: [DomainDisplayInfo]) async {
        for domain in domains {
            if let i = domainsWithDisplayInfo.firstIndex(where: { $0.displayInfo.isSameEntity(domain) }) {
                domainsWithDisplayInfo[i].displayInfo.setOrder(domain.order)
            }
        }
        self.domainsWithDisplayInfo = domainsWithDisplayInfo.sorted()
        notifyListenersWith(result: .success(.domainsUpdated(domains)))
    }
    
    func aggregateData(shouldRefreshPFP: Bool) async {
        
    }
    
    func reverseResolutionDomain(for wallet: UDWallet) async -> DomainDisplayInfo? { await getDomainsDisplayInfo().first }
    func isReverseResolutionChangeAllowed(for wallet: UDWallet) async -> Bool { true }
    func isReverseResolutionChangeAllowed(for domain: DomainDisplayInfo) async -> Bool { true }
    func isReverseResolutionSetupInProgress(for domainName: DomainName) async -> Bool { false }
    func isReverseResolutionSet(for domainName: DomainName) async -> Bool { false }
    func mintDomains(_ domains: [String],
                     paidDomains: [String],
                     domainsOrderInfoMap: SortDomainsOrderInfoMap,
                     to wallet: UDWallet,
                     userEmail: String,
                     securityCode: String) async throws -> [MintingDomain] {
        try await Task.sleep(seconds: 0.3)

        let transactions: [TransactionItem] = []
        let mintingDomains = domains.map({ domain in MintingDomain(name: domain,
                                                                   walletAddress: wallet.address,
                                                                   isPrimary: false,
                                                                   transactionId: 0,
                                                                   transactionHash: transactions.first(where: { $0.domainName == domain })?.transactionHash) })
        return mintingDomains
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

extension MockDataAggregatorService: UDWalletsServiceListener {
    func walletsDataUpdated(notification: UDWalletsServiceNotification) {
        Task {
            switch notification {
            case .walletsUpdated(let wallets):
                let walletsInfo = await getWalletsWithInfo()
                notifyListenersWith(result: .success(.walletsListUpdated(walletsInfo)))
            case .reverseResolutionDomainChanged(let domainName):
                let walletsInfo = await getWalletsWithInfo()
                notifyListenersWith(result: .success(.walletsListUpdated(walletsInfo)))
                
                let domains = await getDomainsDisplayInfo()
                notifyListenersWith(result: .success(.domainsUpdated(domains)))
            case .walletRemoved: return 
            }
        }
    }
}

// MARK: - Private methods
private extension MockDataAggregatorService {
    func notifyListenersWith(result: DataAggregationResult) {
        listeners.forEach { holder in
            holder.listener?.dataAggregatedWith(result: result)
        }
    }
}
