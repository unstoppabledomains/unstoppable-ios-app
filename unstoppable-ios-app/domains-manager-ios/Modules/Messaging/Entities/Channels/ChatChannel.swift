//
//  ChatChannel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

class ChatChannel: Hashable {
    
    let id: UUID
    let avatarURL: URL?
    let lastMessage: ChatMessageType?
    let unreadMessagesCount: Int
   
    init(id: UUID = .init(),
         avatarURL: URL?,
         lastMessage: ChatMessageType?,
         unreadMessagesCount: Int) {
        self.id = id
        self.avatarURL = avatarURL
        self.lastMessage = lastMessage
        self.unreadMessagesCount = unreadMessagesCount
    }
    
    static func == (lhs: ChatChannel, rhs: ChatChannel) -> Bool {
        lhs.id == rhs.id &&
        lhs.avatarURL == rhs.avatarURL &&
        lhs.lastMessage == rhs.lastMessage &&
        lhs.unreadMessagesCount == rhs.unreadMessagesCount
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(avatarURL)
        hasher.combine(lastMessage)
        hasher.combine(unreadMessagesCount)
    }
    
}
