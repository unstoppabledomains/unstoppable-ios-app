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
    var balance: [ProfileWalletBalance]
    var rrDomain: DomainDisplayInfo?
    
    var address: String { udWallet.address }
    var displayName: String { displayInfo.displayName }
    
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
