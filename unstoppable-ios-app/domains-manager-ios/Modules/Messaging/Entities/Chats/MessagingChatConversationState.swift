//
//  MessagingChatConversationState.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.06.2023.
//

import Foundation

enum MessagingChatConversationState: Hashable {
    case newChat(MessagingChatNewConversationDescription)
    case existingChat(MessagingChatDisplayInfo)
    
    var userInfo: MessagingChatUserDisplayInfo? {
        switch self {
        case .newChat(let description):
            return description.userInfo
        case .existingChat(let messagingChatDisplayInfo):
            return messagingChatDisplayInfo.type.otherUserDisplayInfo
        }
    }
    
    var isGroupConversation: Bool {
        switch self {
        case .existingChat(let chat):
            return chat.isGroupChat
        case .newChat:
            return false
        }
    }
    
    var messagingService: MessagingServiceIdentifier {
        switch self {
        case .newChat(let description):
            return description.messagingService
        case .existingChat(let chat):
            return chat.serviceIdentifier
        }
    }
}

struct MessagingChatNewConversationDescription: Hashable {
    let userInfo: MessagingChatUserDisplayInfo
    let messagingService: MessagingServiceIdentifier
}
