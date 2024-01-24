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
            
            
            let balance: [WalletTokenPortfolio] = [.init(address: $0.address,
                                                         symbol: "ETH",
                                                         name: "Ethereum",
                                                         type: "native",
                                                         firstTx: nil, lastTx: nil,
                                                         blockchainScanUrl: "https://etherscan.io/address/\($0.address)", 
                                                         balance: "1",
                                                         balanceAmt: 1,
                                                         tokens: nil,
                                                         stats: nil,
//                                                         nfts: nil,
                                                         value: .init(marketUsd: "$2,206.70",
                                                                      marketUsdAmt: 2206.7,
                                                                      walletUsd: "$2,206.70",
                                                                      walletUsdAmt: 2206.7),
                                                         totalValueUsdAmt: 2206.7,
                                                         totalValueUsd: "$2,206.70"),
                                                   .init(address: $0.address,
                                                         symbol: "MATIC",
                                                         name: "Polygon",
                                                         type: "native",
                                                         firstTx: nil, lastTx: nil,
                                                         blockchainScanUrl: "https://polygonscan.com/address/\($0.address)",
                                                         balance: "1",
                                                         balanceAmt: 1,
                                                         tokens: [.init(type: "erc20",
                                                                        name: "(PoS) Tether USD", 
                                                                        address: $0.address,
                                                                        symbol: "USDT",
                                                                        logoUrl: nil,
                                                                        balance: "9.2",
                                                                        balanceAmt: 9.2,
                                                                        value: .init(marketUsd: "$1",
                                                                                     marketUsdAmt: 1,
                                                                                     walletUsd: "$9.2",
                                                                                     walletUsdAmt: 9.2))],
                                                         stats: nil,
//                                                         nfts: nil,
                                                         value: .init(marketUsd: "$0.71",
                                                                      marketUsdAmt: 0.71,
                                                                      walletUsd: "$0.71", 
                                                                      walletUsdAmt: 0.71),
                                                         totalValueUsdAmt: 0.71,
                                                         totalValueUsd: "$0.71")]
            
            return WalletEntity(udWallet: $0.wallet,
                                displayInfo: $0.displayInfo!,
                                domains: domains,
                                nfts: nfts,
                                balance: balance,
                                rrDomain: domains.randomElement())
            
        }
    }
}
