//
//  WalletEntity.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import Foundation

struct WalletEntity: Codable {
    
    let address: String 
    let ethFullAddress: String
    let udWallet: UDWallet
    let displayInfo: WalletDisplayInfo
    var domains: [DomainDisplayInfo]
    var nfts: [NFTDisplayInfo]
    var balance: [WalletTokenPortfolio]
    var rrDomain: DomainDisplayInfo?
    
    init(udWallet: UDWallet, displayInfo: WalletDisplayInfo, domains: [DomainDisplayInfo], nfts: [NFTDisplayInfo], balance: [WalletTokenPortfolio], rrDomain: DomainDisplayInfo? = nil) {
        self.address = udWallet.address
        self.ethFullAddress = address.ethChecksumAddress()
        self.udWallet = udWallet
        self.displayInfo = displayInfo
        self.domains = domains
        self.nfts = nfts
        self.balance = balance
        self.rrDomain = rrDomain
    }
}

// MARK: - Open methods
extension WalletEntity {
    
    var displayName: String { displayInfo.displayName }
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
}

extension WalletEntity: Identifiable {
    var id: String { address }
}

extension WalletEntity: Hashable {
    static func == (lhs: WalletEntity, rhs: WalletEntity) -> Bool {
        lhs.displayInfo == rhs.displayInfo &&
        lhs.domains == rhs.domains &&
        lhs.nfts == rhs.nfts &&
        lhs.balance == rhs.balance &&
        lhs.rrDomain == rhs.rrDomain
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(displayInfo)
        hasher.combine(domains)
        hasher.combine(nfts)
        hasher.combine(balance)
        hasher.combine(rrDomain)
    }
}
