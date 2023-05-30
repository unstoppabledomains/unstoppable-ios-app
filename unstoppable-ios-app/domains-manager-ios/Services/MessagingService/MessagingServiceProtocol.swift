//
//  MessagingServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

//MARK: - This is draft implementation to make UI done.
protocol MessagingServiceProtocol {
    func getChannelsForDomain(_ domain: DomainDisplayInfo) async -> [ChatChannelType]
    func getNumberOfUnreadMessagesInChannelsForDomain(_ domain: DomainDisplayInfo) async -> Int
    func getMessagesForChannel(_ channel: ChatChannelType) -> [ChatMessageType]
}


protocol MessagingAPIServiceProtocol { }
protocol MessagingWebSocketsServiceProtocol { }

typealias MessagingWebSocketEventCallback = (MessagingWebSocketEvent)->()
enum MessagingWebSocketEvent {
    case userFeeds
    case userSpamFeeds
    case chatReceivedMessage
    case chatGroups
}


protocol MessagingStorageServiceProtocol { }



