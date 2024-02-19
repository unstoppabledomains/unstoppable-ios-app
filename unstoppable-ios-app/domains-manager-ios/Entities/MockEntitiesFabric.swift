//
//  MockEntitiesFabric.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.07.2023.
//

import UIKit

struct MockEntitiesFabric {
    
    static let remoteImageURL = URL(string: "https://images.unsplash.com/photo-1689704059186-2c5d7874de75?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80")!
    
}

// MARK: - Messaging
extension MockEntitiesFabric {
    enum Reactions {
        static let reactionsToTest: [MessageReactionDescription] =
        [.init(content: "😜", messageId: "1", referenceMessageId: "1", isUserReaction: true),
         .init(content: "😜", messageId: "1", referenceMessageId: "1", isUserReaction: false),
         .init(content: "😅", messageId: "1", referenceMessageId: "1", isUserReaction: false),
         .init(content: "🤓", messageId: "1", referenceMessageId: "1", isUserReaction: false),
         .init(content: "🫂", messageId: "1", referenceMessageId: "1", isUserReaction: false),
         .init(content: "😜", messageId: "1", referenceMessageId: "1", isUserReaction: false)]
    }
    enum Messaging {
        static func newChatConversationState() -> MessagingChatConversationState {
            .newChat(.init(userInfo: .init(wallet: "123"), messagingService: .xmtp))
        }
        
        static func existingChatConversationState(isGroup: Bool) -> MessagingChatConversationState {
            .existingChat(isGroup ? mockGroupChat() : mockPrivateChat())
        }
        
        static func mockPrivateChat() -> MessagingChatDisplayInfo {
            let chatId = UUID().uuidString
            let sender = chatSenderFor(isThisUser: true)
            let avatarURL = URL(string: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/kuplin.hi/f9bed9e5-c6e5-4946-9c32-a655d87e670c.png")
            let lastMessage: MessagingChatMessageDisplayInfo? = nil
            let unreadMessagesCount = 0
            let chat = MessagingChatDisplayInfo(id: chatId,
                                                thisUserDetails: sender.userDisplayInfo,
                                                avatarURL: avatarURL,
                                                serviceIdentifier: .xmtp,
                                                type: .private(.init(otherUser: sender.userDisplayInfo)),
                                                unreadMessagesCount: unreadMessagesCount,
                                                isApproved: true,
                                                lastMessageTime: lastMessage?.time ?? Date(),
                                                lastMessage: lastMessage)
            
            return chat
        }
        
        static func mockGroupChat() -> MessagingChatDisplayInfo {
            let chatId = UUID().uuidString
            let sender = chatSenderFor(isThisUser: true)
            let avatarURL = URL(string: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/kuplin.hi/f9bed9e5-c6e5-4946-9c32-a655d87e670c.png")
            let lastMessage: MessagingChatMessageDisplayInfo? = nil
            let unreadMessagesCount = 0
            let chat = MessagingChatDisplayInfo(id: chatId,
                                                thisUserDetails: sender.userDisplayInfo,
                                                avatarURL: avatarURL,
                                                serviceIdentifier: .xmtp,
                                                type: .group(.init(members: [sender.userDisplayInfo],
                                                                   pendingMembers: [],
                                                                   name: "Group chat",
                                                                   adminWallets: [],
                                                                   isPublic: false)),
                                                unreadMessagesCount: unreadMessagesCount,
                                                isApproved: true,
                                                lastMessageTime: lastMessage?.time ?? Date(),
                                                lastMessage: lastMessage)
            
            return chat
        }
        
        static func createMessagesForUITesting() -> [MessagingChatMessageDisplayInfo] {
            [createTextMessage(id: "1",
                               text: "Hello my friend", 
                               isThisUser: false),
             createTextMessage(id: "2",
                               text: "Hi!", 
                               isThisUser: true),
             createTextMessage(id: "21",
                               text: "I'm failed!",
                               isThisUser: true,
                               deliveryState: .failedToSend),
             createTextMessage(id: "22",
                               text: "And i'm sending",
                               isThisUser: true,
                               deliveryState: .sending),
             createImageMessage(id: "3",
                                image: UIImage.Preview.previewLandscape,
                                isThisUser: false),
             createImageMessage(id: "31",
                                image: UIImage.Preview.previewPortrait,
                                isThisUser: false),
             createImageMessage(id: "32",
                                image: UIImage.Preview.previewSquare,
                                isThisUser: false),
             createImageMessage(id: "33",
                                image: nil,
                                isThisUser: false),
             createImageMessage(id: "4",
                                image: UIImage.Preview.previewPortrait,
                                isThisUser: true),
             createImageMessage(id: "4",
                                image: nil,
                                isThisUser: true),
             createImageMessage(id: "41",
                                image: UIImage.Preview.previewSquare,
                                isThisUser: true,
                                deliveryState: .failedToSend),
             createImageMessage(id: "42",
                                image: UIImage.Preview.previewLandscape,
                                isThisUser: true,
                                deliveryState: .sending)]
        }
        
        static func createTextMessage(id: String = UUID().uuidString,
                                      text: String,
                                      isThisUser: Bool,
                                      deliveryState: MessagingChatMessageDisplayInfo.DeliveryState = .delivered) -> MessagingChatMessageDisplayInfo {
            let sender = chatSenderFor(isThisUser: isThisUser)
            let textDetails = MessagingChatMessageTextTypeDisplayInfo(text: text)
            
            return MessagingChatMessageDisplayInfo(id: id,
                                                   chatId: "2",
                                                   userId: "1",
                                                   senderType: sender,
                                                   time: Date(),
                                                   type: .text(textDetails),
                                                   isRead: false,
                                                   isFirstInChat: true,
                                                   deliveryState: deliveryState,
                                                   isEncrypted: false)
        }
        
        static func createImageMessage(id: String = UUID().uuidString,
                                       image: UIImage?,
                                       isThisUser: Bool,
                                       deliveryState: MessagingChatMessageDisplayInfo.DeliveryState = .delivered) -> MessagingChatMessageDisplayInfo {
            let sender = chatSenderFor(isThisUser: isThisUser)

            var imageDetails = MessagingChatMessageImageBase64TypeDisplayInfo(base64: "")
            imageDetails.image = image
            return MessagingChatMessageDisplayInfo(id: id,
                                                   chatId: "2",
                                                   userId: "1",
                                                   senderType: sender,
                                                   time: Date(),
                                                   type: .imageBase64(imageDetails),
                                                   isRead: false,
                                                   isFirstInChat: true,
                                                   deliveryState: deliveryState,
                                                   isEncrypted: false)
            
            
        }
        
        static func chatSenderFor(user: MessagingChatUserDisplayInfo? = nil,
                                  isThisUser: Bool) -> MessagingChatSender {
            let user = user ?? messagingChatUserDisplayInfo(domainName: "oleg.x", withPFP: true)
            
            return isThisUser ? .thisUser(user) : .otherUser(user)
        }
        
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
                let domains = Domains.mockDomainDisplayInfo(ownerWallet: $0.wallet.address)
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
    
    enum Domains {
        
        static func mockDomainDisplayInfo(ownerWallet: String) -> [DomainDisplayInfo] {
            var domains = [DomainDisplayInfo]()
            let tlds: [String] = ["x", "nft", "unstoppable"]
            
            for tld in tlds {
                for i in 0..<5 {
                    let domain = DomainDisplayInfo(name: "oleg_\(i)_\(ownerWallet.last!).\(tld)",
                                                   ownerWallet: ownerWallet,
                                                   blockchain: .Matic,
                                                   isSetForRR: false)
                    domains.append(domain)
                }
                
                for i in 0..<5 {
                    let domain = DomainDisplayInfo(name: "subdomain_\(i).oleg_0.\(tld)",
                                                   ownerWallet: ownerWallet,
                                                   blockchain: .Matic,
                                                   isSetForRR: false)
                    domains.append(domain)
                }
            }
            
            return domains
        }

        static func mockFirebaseDomains() -> [FirebaseDomain] {
            [
                /// Parking purchased
                .init(claimStatus: "",
                   internalCustody: true,
                   purchasedAt: Date(),
                   parkingExpiresAt: Date().adding(days: 40),
                   parkingTrial: false,
                   domainId: 0,
                   blockchain: "MATIC",
                   name: "parked.x",
                   ownerAddress: "123"),
                /// Parking expires soon
                .init(claimStatus: "",
                      internalCustody: true,
                      purchasedAt: Date(),
                      parkingExpiresAt: Date().adding(days: 10),
                      parkingTrial: false,
                      domainId: 0,
                      blockchain: "MATIC",
                      name: "parking_exp_soon.x",
                      ownerAddress: "123"),
                ///Parking trial
                .init(claimStatus: "",
                      internalCustody: true,
                      purchasedAt: Date(),
                      parkingExpiresAt: Date().addingTimeInterval(60 * 60 * 24),
                      parkingTrial: true,
                      domainId: 0,
                      blockchain: "MATIC",
                      name: "on_trial.x",
                      ownerAddress: "123"),
                ///Parking expired
                .init(claimStatus: "",
                      internalCustody: true,
                      purchasedAt: Date(),
                      parkingExpiresAt: Date().addingTimeInterval(-60 * 60 * 24),
                      parkingTrial: false,
                      domainId: 0,
                      blockchain: "MATIC",
                      name: "expired.x",
                      ownerAddress: "123"),
                ///Free parking
                .init(claimStatus: "",
                      internalCustody: true,
                      purchasedAt: Date(),
                      parkingExpiresAt: nil,
                      parkingTrial: false,
                      domainId: 0,
                      blockchain: "MATIC",
                      name: "free.x",
                      ownerAddress: "123")
            ]
            
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
