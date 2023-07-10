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
            switch messagingChatDisplayInfo.type {
            case .private(let details):
                return details.otherUser
            case .group:
                return nil
            }
        }
    }
}
