//
//  MessagingWebSocketEvent.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

typealias MessagingWebSocketEventCallback = (MessagingWebSocketEvent)->()

enum MessagingWebSocketEvent {
    case userFeeds(_ feed: PushInboxNotification)
    case userSpamFeeds(_ feeds: [PushInboxNotification])
    case chatReceivedMessage(_ message: MessagingWebSocketMessageEntity)
    case chatGroups
}
