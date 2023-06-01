//
//  MessagingChatDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

struct MessagingChatDisplayInfo: Hashable {
    let id: String
    let thisUserDetails: MessagingChatUserDisplayInfo
    let avatarURL: URL?
    let type: MessagingChatType
    let unreadMessagesCount: Int
    let lastMessage: MessagingChatMessageDisplayInfo?
}
