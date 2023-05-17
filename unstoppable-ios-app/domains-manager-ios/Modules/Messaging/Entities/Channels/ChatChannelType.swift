//
//  ChatChannelType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

enum ChatChannelType: Hashable {
    case domain(channel: DomainChatChannel)
    
    var avatarURL: URL? {
        switch self {
        case .domain(let channel):
            return channel.avatarURL
        }
    }
    
    var lastMessage: ChatMessageType? {
        switch self {
        case .domain(let channel):
            return channel.lastMessage
        }
    }
    
    var unreadMessagesCount: Int {
        switch self {
        case .domain(let channel):
            return channel.unreadMessagesCount
        }
    }
}
