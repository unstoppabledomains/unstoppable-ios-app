//
//  MessagingWebSocketEvent.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

typealias MessagingWebSocketEventCallback = (MessagingWebSocketEvent)->()

enum MessagingWebSocketEvent {
    case channelNewFeed(MessagingNewsChannelFeed, channelAddress: String, recipients: [String])
    case channelSpamFeed(MessagingNewsChannelFeed, channelAddress: String, recipients: [String])
    case newChat(MessagingWebSocketChatEntity)
    case chatReceivedMessage(MessagingWebSocketMessageEntity)
    case groupChatReceivedMessage(MessagingWebSocketGroupMessageEntity)
}
