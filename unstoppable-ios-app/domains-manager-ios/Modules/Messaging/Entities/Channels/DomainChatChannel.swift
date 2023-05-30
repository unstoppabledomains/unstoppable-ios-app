//
//  DomainChatChannel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

final class DomainChatChannel: ChatChannel {
    
    let domainName: DomainName
    
    init(id: String,
         avatarURL: URL?,
         lastMessage: ChatMessageType?,
         unreadMessagesCount: Int,
         domainName: DomainName) {
        self.domainName = domainName
        super.init(id: id, avatarURL: avatarURL, lastMessage: lastMessage, unreadMessagesCount: unreadMessagesCount)
    }
}
