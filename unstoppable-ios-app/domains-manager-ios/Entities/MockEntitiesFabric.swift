//
//  MockEntitiesFabric.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.07.2023.
//

import Foundation

struct MockEntitiesFabric {
    
    static let remoteImageURL = URL(string: "https://images.unsplash.com/photo-1689704059186-2c5d7874de75?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80")!
    
}

// MARK: - Messaging
extension MockEntitiesFabric {
    enum Messaging {
        static func messagingChatUserDisplayInfo(wallet: String = "13123",
                                                 domainName: String? = nil,
                                                 withPFP: Bool) -> MessagingChatUserDisplayInfo {
            let pfpURL: URL? = !withPFP ? nil : MockEntitiesFabric.remoteImageURL
            return MessagingChatUserDisplayInfo(wallet: wallet, domainName: domainName, pfpURL: pfpURL)
        }
    }
    
    enum Wallet {
        static func mockEntities() -> [WalletEntity] {
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
}
