//
//  MessagingChatConversationState.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.06.2023.
//

import Foundation

enum MessagingChatConversationState {
    case newChat(MessagingChatUserDisplayInfo)
    case existingChat(MessagingChatDisplayInfo)
    
    var userInfo: MessagingChatUserDisplayInfo? {
        switch self {
        case .newChat(let userInfo):
            return userInfo
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
}
