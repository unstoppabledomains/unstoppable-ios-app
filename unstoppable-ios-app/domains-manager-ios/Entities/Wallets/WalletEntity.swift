//
//  WalletEntity.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import Foundation

struct WalletEntity: Codable {
    
    let udWallet: UDWallet
    let displayInfo: WalletDisplayInfo
    var domains: [DomainDisplayInfo]
    var nfts: [NFTDisplayInfo]
    var balance: [WalletTokenPortfolio]
    var rrDomain: DomainDisplayInfo?
    
    var address: String { udWallet.address }
    var displayName: String { displayInfo.displayName }
    var totalBalance: Int { 20000 }
    
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

// MARK: - Open methods
extension WalletEntity {
    static func mock() -> [WalletEntity] {
        WalletWithInfo.mock.map {
            let domains = createMockDomains()
            let numOfNFTs = Int(arc4random_uniform(10) + 1)
            let nfts = (0...numOfNFTs).map { _ in  NFTDisplayInfo.mock() }
            return WalletEntity(udWallet: $0.wallet,
                                displayInfo: $0.displayInfo!,
                                domains: domains,
                                nfts: nfts,
                                balance: [],
                                rrDomain: domains.randomElement())
            
        }
    }
}
