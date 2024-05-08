//
//  WalletEntity.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import Foundation

struct WalletEntity: Codable, Hashable {
    
    let address: String 
    let ethFullAddress: String
    private(set) var udWallet: UDWallet
    private(set) var displayInfo: WalletDisplayInfo
    private(set) var domains: [DomainDisplayInfo]
    var nfts: [NFTDisplayInfo]
    private(set) var balance: [WalletTokenPortfolio]
    var rrDomain: DomainDisplayInfo?
    var portfolioRecords: [WalletPortfolioRecord]
    
    init(udWallet: UDWallet, displayInfo: WalletDisplayInfo, domains: [DomainDisplayInfo], nfts: [NFTDisplayInfo], balance: [WalletTokenPortfolio], rrDomain: DomainDisplayInfo? = nil, portfolioRecords: [WalletPortfolioRecord] = []) {
        self.address = udWallet.address
        self.ethFullAddress = address.ethChecksumAddress()
        self.udWallet = udWallet
        self.displayInfo = displayInfo
        self.domains = domains
        self.nfts = nfts
        self.balance = balance
        self.rrDomain = rrDomain
        self.portfolioRecords = portfolioRecords
    }
    
    mutating func udWalletUpdated(_ udWallet: UDWallet) {
        self.udWallet = udWallet
        if let displayInfo = WalletDisplayInfo(wallet: udWallet,
                                               domainsCount: domains.count,
                                               udDomainsCount: domains.lazy.filter { $0.isUDDomain }.count,
                                               reverseResolutionDomain: rrDomain) {
            self.displayInfo = displayInfo
        }
    }
    
    mutating func changeRRDomain(_ domain: DomainDisplayInfo) {
        self.rrDomain = domain
        if let domainIndex = domains.firstIndex(where: { $0.isSameEntity(domain) }) {
            self.domains[domainIndex] = domain
        }
        displayInfo.reverseResolutionDomain = domain
    }
    
    mutating func updateDomains(_ domains: [DomainDisplayInfo]) {
        let rrDomain = domains.first(where: { $0.isSetForRR })
        self.domains = domains
        self.rrDomain = rrDomain
        displayInfo.reverseResolutionDomain = rrDomain
        displayInfo.domainsCount = domains.count
        displayInfo.udDomainsCount = domains.lazy.filter { $0.isUDDomain }.count
    }
    
    mutating func updateBalance(_ balance: [WalletTokenPortfolio]) {
        self.balance = balance
        trackBalanceRecords()
    }
    
    private mutating func trackBalanceRecords() {
        let currentValue = totalBalance
        let currentRecord = WalletPortfolioRecord(wallet: address, date: Date(), value: currentValue)
        
        var records = WalletPortfolioRecordsStorage.instance.getRecords(for: address)
        
        if let previousRecord = records.last {
            if previousRecord.date.isSameDayAs(currentRecord.date) {
                /// Replace latest record if from same date (today)
                records[records.count - 1] = currentRecord
            } else {
                records.append(currentRecord)
            }
        } else {
            records = [currentRecord]
        }
        
        records = records.filter { $0.date.daysDifferenceBetween(date: Date()) <= 30 }
        
        self.portfolioRecords = records
        WalletPortfolioRecordsStorage.instance.saveRecords(records, for: address)
    }
}

// MARK: - Open methods
extension WalletEntity {
    
    var displayName: String { displayInfo.displayName }
    var domainOrDisplayName: String { nameOfCurrentRepresentingDomain == nil ? displayName : nameOfCurrentRepresentingDomain! }
    var totalBalance: Double { balance.reduce(0.0, { $0 + $1.totalTokensBalance }) }
    var udDomains: [DomainDisplayInfo] { domains.filter { $0.isUDDomain }}
    var profileDomainName: String? { rrDomain?.name }
    
    func balanceFor(blockchainType: BlockchainType) -> WalletTokenPortfolio? {
        balance.first(where: { $0.symbol == blockchainType.rawValue })
    }
    
    func isReverseResolutionChangeAllowed() -> Bool {
        let domainsAvailableForRR = domains.availableForRRItems()
        guard !domainsAvailableForRR.isEmpty else { return false }
        
        let isAllowedToSetRR = domainsAvailableForRR.first(where: { !$0.isReverseResolutionChangeAllowed() }) == nil
        return isAllowedToSetRR
    }
    
    func isOwningDomain(_ domainName: DomainName) -> Bool {
        domains.first(where: { $0.name == domainName }) != nil
    }
    
    func getDomainToViewPublicProfile() -> DomainDisplayInfo? {
        rrDomain ?? domains.interactableItems().first
    }
}

extension WalletEntity: Identifiable {
    var id: String { address }
}

extension WalletEntity {
    enum RepresentingDomainState {
        case noRRDomain, udDomain(DomainDisplayInfo), ensDomain(DomainDisplayInfo)
    }
    
    func getCurrentWalletRepresentingDomainState() -> RepresentingDomainState {
        if let rrDomain = rrDomain {
            return .udDomain(rrDomain)
        } else if let ensDomain = domains.first(where: { $0.isENSDomain }),
                  !isReverseResolutionChangeAllowed() {
            return .ensDomain(ensDomain)
        }
        return .noRRDomain
    }
    
    var nameOfCurrentRepresentingDomain: String? {
        switch getCurrentWalletRepresentingDomainState() {
        case .udDomain(let domain), .ensDomain(let domain):
            return domain.name
        case .noRRDomain: 
            return nil
        }
    }
}


extension WalletEntity {
    enum AssetsType {
        case singleChain(BalanceTokenUIDescription)
        case multiChain([BalanceTokenUIDescription])
    }
    
    func getAssetsType() -> AssetsType {
        if case .mpc = udWallet.type {
            do {
//                return .multiChain([MockEntitiesFabric.Tokens.mockEthToken(),
//                                    MockEntitiesFabric.Tokens.mockMaticToken()])
                
                let mpcMetadata = try udWallet.extractMPCMetadata()
                let tokens = try appContext.mpcWalletsService.getTokens(for: mpcMetadata)
                return .multiChain(tokens)
            } catch {
                return getDefaultAssetType()
            }
        }
        
        return getDefaultAssetType()
    }
    
    private func getDefaultAssetType() -> AssetsType {
        let blockchain = BlockchainType.Ethereum
        return .singleChain(BalanceTokenUIDescription(address: ethFullAddress,
                                                      chain: blockchain.rawValue,
                                                      symbol: blockchain.rawValue,
                                                      name: blockchain.fullName,
                                                      balance: 0,
                                                      balanceUsd: 0,
                                                      marketUsd: nil,
                                                      marketPctChange24Hr: nil))
    }
}

extension Array where Element == WalletEntity {
    func findWithAddress(_ address: HexAddress?) -> Element? {
        guard let address = address?.normalized else { return nil }
        
        return first(where: { $0.address.normalized == address })
    }
    
    func combinedDomains() -> [DomainDisplayInfo] {
        reduce([DomainDisplayInfo](), { $0 + $1.domains })
    }
    
    func findOwningDomain(_ domainName: DomainName) -> Element? {
        first(where: { $0.isOwningDomain(domainName) })
    }
}

struct WalletPortfolioRecord: Hashable, Codable {
    let wallet: String
    let date: Date
    let value: Double
    let timestamp: Double

    init(wallet: String,
         date: Date,
         value: Double) {
        self.wallet = wallet
        self.date = date
        self.value = value
        self.timestamp = date.timeIntervalSince1970
    }
}
