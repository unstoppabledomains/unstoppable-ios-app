//
//  PreviewWalletNFTsService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import Foundation

final class PreviewWalletNFTsService {
    
}

// MARK: - Open methods
extension PreviewWalletNFTsService: WalletNFTsServiceProtocol {
    func getImageNFTsFor(domainName: String) async throws -> [NFTModel] {
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
    }
    
    func refreshNFTsFor(domainName: String) async throws -> [NFTModel] {
        []
    }
    
    func addListener(_ listener: WalletNFTsServiceListener) {
        
    }
    
    func removeListener(_ listener: WalletNFTsServiceListener) {
        
    }
}
