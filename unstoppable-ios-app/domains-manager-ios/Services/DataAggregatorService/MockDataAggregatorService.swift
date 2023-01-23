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
        let domains = await getDomains()
        let domainsCount = domains.filter({ $0.isOwned(by: [wallet] )}).count
        return WalletDisplayInfo(wallet: wallet,
                                 domainsCount: domainsCount,
                                 reverseResolutionDomain: rrDomain)
        
    }
    
    func getDomains() async -> [DomainItem] {
        await getCachedDomainsFor(wallets: walletsService.getUserWallets())
    }
    func getCachedDomainsFor(wallets: [UDWallet]) async -> [DomainItem] {
        var domains = try! await domainsService.updateDomainsList(for: wallets)
        let primaryDomainName = UserDefaults.primaryDomainName
        for i in 0..<domains.count {
            domains[i].isPrimary = domains[i].name == primaryDomainName
            domains[i].isUpdatingRecords = i == 4
        }
        return domains
    }
     
    func setPrimaryDomainWith(name: String) async {
        UserDefaults.primaryDomainName = name
        let domains = await getDomains()
        notifyListenersWith(result: .success(.domainsUpdated(domains)))
    }
    
    func aggregateData() async {
        
    }
    
    func reverseResolutionDomain(for wallet: UDWallet) async -> DomainItem? { domainsService.getCachedDomainsFor(wallets: [wallet]).first }
    func isReverseResolutionChangeAllowed(for wallet: UDWallet) async -> Bool { true }
    func isReverseResolutionChangeAllowed(for domain: DomainItem) async -> Bool { true }
    func isReverseResolutionSetupInProgress(for domainName: DomainName) async -> Bool { false }
    func isReverseResolutionSet(for domainName: DomainName) async -> Bool { false }
    func mintDomains(_ domains: [String],
                     paidDomains: [String],
                     newPrimaryDomain: String?,
                     to wallet: UDWallet,
                     userEmail: String,
                     securityCode: String) async throws -> [MintingDomain] {
        try await Task.sleep(seconds: 0.3)

        let transactions: [TransactionItem] = []
        let mintingDomains = domains.map({ domain in MintingDomain(name: domain,
                                                                   walletAddress: wallet.address,
                                                                   isPrimary: domain == newPrimaryDomain,
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
                
                let domains = await getDomains()
                notifyListenersWith(result: .success(.domainsUpdated(domains)))
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
