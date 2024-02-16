//
//  MessagingBlockUserInChatType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.01.2024.
//

import Foundation

enum MessagingBlockUserInChatType {
    case chat(MessagingChatDisplayInfo) // Block chat
    case userInGroup(MessagingChatUserDisplayInfo, MessagingChatDisplayInfo)
    
    var chat: MessagingChatDisplayInfo {
        switch self {
        case .chat(let chat), .userInGroup(_, let chat):
            return chat
        }
    }
}
