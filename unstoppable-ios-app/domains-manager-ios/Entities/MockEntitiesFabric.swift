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
    enum Reactions {
        static let reactionsToTest: [ReactionCounter] =
        [.init(content: "😜", messageId: "1", referenceMessageId: "1", isUserReaction: true),
         .init(content: "😜", messageId: "1", referenceMessageId: "1", isUserReaction: false),
         .init(content: "😅", messageId: "1", referenceMessageId: "1", isUserReaction: false),
         .init(content: "🤓", messageId: "1", referenceMessageId: "1", isUserReaction: false),
         .init(content: "🫂", messageId: "1", referenceMessageId: "1", isUserReaction: false),
         .init(content: "😜", messageId: "1", referenceMessageId: "1", isUserReaction: false)]
    }
    enum Messaging {
        static func messagingChatUserDisplayInfo(wallet: String = "13123",
                                                 domainName: String? = nil,
                                                 withPFP: Bool) -> MessagingChatUserDisplayInfo {
            let pfpURL: URL? = !withPFP ? nil : MockEntitiesFabric.remoteImageURL
            return MessagingChatUserDisplayInfo(wallet: wallet, domainName: domainName, pfpURL: pfpURL)
        }
    }
}
