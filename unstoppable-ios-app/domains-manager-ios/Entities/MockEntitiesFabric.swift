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
                let domains = Domains.mockDomainDisplayInfo()
                let numOfNFTs = Int(arc4random_uniform(10) + 1)
                let nfts = (0...numOfNFTs).map { _ in  NFTs.mockDisplayInfo() }
                
                
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
    
    enum Domains {
        
        static func mockDomainDisplayInfo() -> [DomainDisplayInfo] {
            var domains = [DomainDisplayInfo]()
            
            for i in 0..<5 {
                let domain = DomainDisplayInfo(name: "oleg_\(i).x",
                                               ownerWallet: "",
                                               blockchain: .Matic,
                                               isSetForRR: false)
                domains.append(domain)
            }
            
            for i in 0..<5 {
                let domain = DomainDisplayInfo(name: "subdomain_\(i).oleg_0.x",
                                               ownerWallet: "",
                                               blockchain: .Matic,
                                               isSetForRR: false)
                domains.append(domain)
            }
            
            return domains
        }

    }
    
    enum NFTs {
        static func mockDisplayInfo() -> NFTDisplayInfo {
            .init(name: "NFT Name",
                  description: "The MUTANT APE YACHT CLUB is a collection of up to 20,000 Mutant Apes that can only be created by exposing an existing Bored Ape to a vial of MUTANT SERUM or by minting a Mutant Ape in the public sale.",
                  imageUrl: URL(string: "https://google.com"),
                  link: "https://google.com",
                  tags: [],
                  collection: "Collection name with long name",
                  collectionLink: URL(string: "https://google.com"),
                  mint: UUID().uuidString,
                  traits: [.init(name: "Background", value: "M1 Orange")],
                  floorPrice: "5.32 MATIC",
                  lastSaleDetails: .init(date: Date().addingTimeInterval(-86400),
                                         symbol: "MATIC",
                                         valueUsd: 2.01,
                                         valueNative: 2.31),
                  chain: .MATIC)
        }
        
        static func mockNFTModels() -> [NFTModel] {
            []
            /*
            [.init(name: "Metropolis Avatar #3041",
                   description: "Introducing your Metropolis Avatar: endlessly customizable even after minting. However, while the accessories are exchangeable, your avatar’s base body (including eyes, nose, mouth, and ears) are Soulbound to you like a signature. This means that if you want to change your base you’ll need to mint a new Soulbound avatar, but don’t worry! All clothing and accessories are wearable across all of your Metropolis avatars as long as they exist within the same wallet.\nThis is a Citizen. Born from the Earth, their desires are more terrestrial in nature. Groundedness, community, creativity, and folklore are some of the things they value above all else. Check out MetropolisWorldLore.io/characters to learn more about their various factions and where you belong!\nHave fun, and welcome to the world!",
                   imageUrl: "https://avatarimg.metropolisworld.net/img/1?a=659&a=407&a=637&a=671&a=488&a=496&a=350&a=2875&a=514&a=3066&a=3292",
                   public: true,
                   link: "https://opensea.io/assets/matic/0xd625d61a57b77970716f7206c528d68ee89cc20c/3041",
                   tags: ["education",
                          "wearable"],
                   collection: "Metropolis Avatars",
                   mint: "0xd625d61a57b77970716f7206c528d68ee89cc20c/3041"),
             .init(name: "@5quirks",
                   description: "Lens Protocol - Handle @5quirks",
                   imageUrl: nil,
                   public: true,
                   link: "https://opensea.io/assets/matic/0xe7e7ead361f3aacd73a61a9bd6c10ca17f38e945/3123716726933408854021964923049795066056821070408923873201131269208661046111",
                   tags: [],
                   collection: "lens Handles",
                   mint: "0xe7e7ead361f3aacd73a61a9bd6c10ca17f38e945/3123716726933408854021964923049795066056821070408923873201131269208661046111"),
             .init(name: "Connect More in 2024",
                   description: "You have used Unstoppable Messaging to connect more in 2024 and are eligible for early access to future campaign mints.",
                   imageUrl: "https://assets.poap.xyz/a92a4baf-9822-4f84-8676-5c7817928542.png",
                   public: true,
                   link: "https://poap.gallery/event/166573",
                   tags: [],
                   collection: "POAP",
                   mint: "6962301/166573"),
             .init(name: "You Met Ada.eth in Las Vegas 2023",
                   description: "The original bearer of this POAP met Ada.eth in Las Vegas, Nevada, United States, in December 2023.",
                   imageUrl: "https://assets.poap.xyz/9fe07a5b-ae81-4e7b-8096-6a122eec0081.png",
                   public: true,
                   link: "https://poap.gallery/event/165115",
                   tags: [],
                   collection: "POAP",
                   mint: "6931229/165115"),
             .init(name: "I met GaryPalmerJr.eth (Las Vegas, Nevada), 2023",
                   description: "The original bearer of this POAP met GaryPalmerJr.eth (in Las Vegas, Nevada, United States), and scanned his physical NFC-ENS card, (December 2023).",
                   imageUrl: "https://assets.poap.xyz/055233d5-7eb3-46cc-b25f-a279e5b15112.gif",
                   public: true,
                   link: "https://poap.gallery/event/165112",
                   tags: [],
                   collection: "POAP",
                   mint: "6931222/165112"),
             .init(name: "GitPOAP: 2023 Push Protocol Contributor",
                   description: "You made at least one contribution to the Push Protocol project in 2023. Your contributions are greatly appreciated!",
                   imageUrl: "https://assets.poap.xyz/gitpoap3a-2023-push-protocol-contributor-2023-logo-1678216506876.png",
                   public: true,
                   link: "https://poap.gallery/event/109032",
                   tags: [],
                   collection: "POAP",
                   mint: "6513349/109032")
            ]
            */
        }
    }
}
