//
//  ChatChannelType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

enum ChatChannelType: Hashable {
    case domain(channel: DomainChatChannel)
    
    var channel: ChatChannel {
        switch self {
        case .domain(let channel):
            return channel
        }
    }
    
    var avatarURL: URL? {
        channel.avatarURL
    }
    
    var lastMessage: ChatMessageType? {
        channel.lastMessage
    }
    
    var unreadMessagesCount: Int {
        channel.unreadMessagesCount
    }
}
