//
//  MockEntitiesFabric.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.07.2023.
//

import UIKit

struct MockEntitiesFabric {
    
}

// MARK: - Messaging
extension MockEntitiesFabric {
    enum ImageURLs: String {
        case sunset = "https://images.unsplash.com/photo-1689704059186-2c5d7874de75?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80"
        case aiAvatar = "https://storage.googleapis.com/unstoppable-client-assets/images/domain/kuplin.hi/f9bed9e5-c6e5-4946-9c32-a655d87e670c.png"
        
        var url: URL { URL(string: rawValue)! }
    }
    
    enum URLs {
        static let generic = URL(string: "https://google.com")!
    }
    
    enum Home {
        @MainActor
        static func createHomeTabRouter(isWebProfile: Bool = false) -> HomeTabRouter {
            let profile: UserProfile
            if isWebProfile {
                profile = Profile.createWebAccountProfile()
            } else {
                profile = Profile.createWalletProfile()
            }
            return HomeTabRouter(profile: profile)
        }
    }
    
    enum Profile {
        static func createWebAccountProfile() -> UserProfile {
            .webAccount(.init(email: "oleg@unstoppabledomains.com"))
        }
        
        static func createWalletProfile(using wallet: WalletEntity? = nil) -> UserProfile {
            let wallet = wallet ?? Wallet.mockEntities().first!
            
            return .wallet(wallet)
        }
    }
    
    enum Wallet {
        static func mockEntities() -> [WalletEntity] {
            WalletWithInfo.mock.map {
                let domains = Domains.mockDomainsDisplayInfo(ownerWallet: $0.wallet.address)
                let numOfNFTs = Int(arc4random_uniform(10) + 1)
                let nfts = (0...numOfNFTs).map { _ in  NFTs.mockDisplayInfo() }
                let addr = $0.wallet.address
                let portfolioRecords: [WalletPortfolioRecord] = [.init(wallet: addr, date: Date().adding(days: -10), value: 6.8),
                                                                 .init(wallet: addr, date: Date().adding(days: -9), value: 5.2),
                                                                 .init(wallet: addr, date: Date().adding(days: -8), value: 22.9),
                                                                 .init(wallet: addr, date: Date().adding(days: -7), value: 22.2),
                                                                 .init(wallet: addr, date: Date().adding(days: -6), value: 27.9),
                                                                 .init(wallet: addr, date: Date().adding(days: -5), value: 23.2),
                                                                 .init(wallet: addr, date: Date().adding(days: -4), value: 37.2),
                                                                 .init(wallet: addr, date: Date().adding(days: -3), value: 32.9),
                                                                 .init(wallet: addr, date: Date().adding(days: -2), value: 35.2),
                                                                 .init(wallet: addr, date: Date().adding(days: -1), value: 32.9),
                                                                 .init(wallet: addr, date: Date(), value: 39.2)]
               
                
                let balance: [WalletTokenPortfolio] = [.init(address: $0.address,
                                                             symbol: "ETH",
                                                             name: "Ethereum",
                                                             type: "native",
                                                             firstTx: nil, lastTx: nil,
                                                             blockchainScanUrl: "https://etherscan.io/address/\($0.address)",
                                                             balanceAmt: 1,
                                                             tokens: nil,
                                                             stats: nil,
                                                             //                                                         nfts: nil,
                                                             value: .init(marketUsd: "$2,206.70",
                                                                          marketUsdAmt: 2206.7,
                                                                          walletUsd: "$2,206.70",
                                                                          walletUsdAmt: 2206.7,
                                                                          marketPctChange24Hr: 0.62),
                                                             totalValueUsdAmt: 2206.7,
                                                             totalValueUsd: "$2,206.70",
                                                             logoUrl: nil),
                                                       .init(address: $0.address,
                                                             symbol: "MATIC",
                                                             name: "Polygon",
                                                             type: "native",
                                                             firstTx: nil, lastTx: nil,
                                                             blockchainScanUrl: "https://polygonscan.com/address/\($0.address)",
                                                             balanceAmt: 1,
                                                             tokens: [.init(type: "erc20",
                                                                            name: "(PoS) Tether USD",
                                                                            address: $0.address,
                                                                            symbol: "USDT",
                                                                            logoUrl: nil,
                                                                            balanceAmt: 9.2,
                                                                            value: .init(marketUsd: "$1",
                                                                                         marketUsdAmt: 1,
                                                                                         walletUsd: "$9.2",
                                                                                         walletUsdAmt: 9.2,
                                                                                         marketPctChange24Hr: -0.18))],
                                                             stats: nil,
                                                             //                                                         nfts: nil,
                                                             value: .init(marketUsd: "$0.71",
                                                                          marketUsdAmt: 0.71,
                                                                          walletUsd: "$0.71",
                                                                          walletUsdAmt: 0.71, 
                                                                          marketPctChange24Hr: 0.02),
                                                             totalValueUsdAmt: 0.71,
                                                             totalValueUsd: "$0.71",
                                                             logoUrl: nil)]
                let hasRRDomain = [true, false].randomElement()!
                
                return WalletEntity(udWallet: $0.wallet,
                                    displayInfo: $0.displayInfo!,
                                    domains: domains,
                                    nfts: nfts,
                                    balance: balance,
                                    rrDomain: hasRRDomain ? domains.randomElement() : nil,
                                    portfolioRecords: portfolioRecords)
                
            }
        }
    }
  
    enum NFTs {
        static func mockDisplayInfo() -> NFTDisplayInfo {
            .init(name: "NFT Name",
                  description: "The MUTANT APE YACHT CLUB is a collection of up to 20,000 Mutant Apes that can only be created by exposing an existing Bored Ape to a vial of MUTANT SERUM or by minting a Mutant Ape in the public sale.",
                  imageUrl: URL(string: "https://google.com"),
                  link: URL(string: "https://google.com"),
                  tags: [],
                  collection: "Collection name with long name",
                  collectionLink: URL(string: "https://google.com"),
                  collectionImageUrl: nil,
                  mint: UUID().uuidString,
                  traits: [.init(name: "Background", value: "M1 Orange")],
                  floorPriceDetails: .init(value: 5.32, currency: "USD"),
                  lastSaleDetails: .init(date: Date().addingTimeInterval(-86400),
                                         symbol: "MATIC",
                                         valueUsd: 2.01,
                                         valueNative: 2.31),
                  rarity: "167 / 373",
                  acquiredDate: Date().addingTimeInterval(-86400),
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
