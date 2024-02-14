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
        
        records = records.filter { $0.date.dateDifferenceBetween(date: Date()).day ?? 0 <= 30 }
        
        self.portfolioRecords = records
        WalletPortfolioRecordsStorage.instance.saveRecords(records, for: address)
    }
}

// MARK: - Open methods
extension WalletEntity {
    
    var displayName: String { displayInfo.displayName }
    var domainOrDisplayName: String { rrDomain == nil ? displayName : rrDomain!.name }
    var totalBalance: Double { balance.reduce(0.0, { $0 + $1.totalTokensBalance }) }
    var udDomains: [DomainDisplayInfo] { domains.filter { $0.isUDDomain }}
    
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

extension Array where Element == WalletEntity {
    func findWithAddress(_ address: HexAddress?) -> Element? {
        guard let address else { return nil }
        
        return first(where: { $0.address == address })
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
