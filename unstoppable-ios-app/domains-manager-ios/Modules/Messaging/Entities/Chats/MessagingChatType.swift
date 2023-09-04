//
//  MessagingChatType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

enum MessagingChatType: Hashable {
    case `private`(MessagingPrivateChatDetails)
    case group(MessagingGroupChatDetails)
    
    var otherUserDisplayInfo: MessagingChatUserDisplayInfo? {
        switch self {
        case .private(let details):
            return details.otherUser
        case .group:
            return nil
        }
    }
}
