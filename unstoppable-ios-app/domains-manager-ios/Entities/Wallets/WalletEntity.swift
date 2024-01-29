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
    var totalBalance: Double { balance.reduce(0.0, { $0 + $1.totalTokensBalance }) }
    
    func balanceFor(blockchainType: BlockchainType) -> WalletTokenPortfolio? {
        balance.first(where: { $0.symbol == blockchainType.rawValue })
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
