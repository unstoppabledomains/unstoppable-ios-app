//
//  MessagingChatSender.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import Foundation

enum MessagingChatSender: Hashable {
    case thisUser(MessagingChatUserDisplayInfo)
    case otherUser(MessagingChatUserDisplayInfo)
    
    var isThisUser: Bool {
        switch self {
        case .thisUser:
            return true
        default:
            return false
        }
    }
    
    var userDisplayInfo: MessagingChatUserDisplayInfo {
        switch self {
        case .thisUser(let user), .otherUser(let user):
            return user
        }
    }
}
