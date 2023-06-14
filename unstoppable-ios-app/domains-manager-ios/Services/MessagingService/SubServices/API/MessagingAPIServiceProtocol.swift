//
//  MessagingAPIServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

protocol MessagingAPIServiceProtocol {
    // Chats
    func getChatsListForUser(_ user: MessagingChatUserProfile,
                             page: Int,
                             limit: Int) async throws -> [MessagingChat]
    func getChatRequestsForUser(_ user: MessagingChatUserProfile,
                                page: Int,
                                limit: Int) async throws -> [MessagingChat]
    
    // Messages
    func getMessagesForChat(_ chat: MessagingChat,
                            options: MessagingAPIServiceLoadMessagesOptions,
                            fetchLimit: Int,
                            for user: MessagingChatUserProfile) async throws -> [MessagingChatMessage]
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChat,
                     by user: MessagingChatUserProfile) async throws -> MessagingChatMessage
    func makeChatRequest(_ chat: MessagingChat,
                         approved: Bool,
                         by user: MessagingChatUserProfile) async throws
    
    // Channels
    func getSubscribedChannelsForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel]
    func getNotificationsInboxFor(wallet: HexAddress,
                                  page: Int,
                                  limit: Int,
                                  isSpam: Bool) async throws -> [MessagingNewsChannelFeed]
    func getFeedFor(channel: MessagingNewsChannel,
                    page: Int,
                    limit: Int) async throws -> [MessagingNewsChannelFeed]
}

enum MessagingAPIServiceLoadMessagesOptions {
    case `default`
    case before(message: MessagingChatMessage)
    case after(message: MessagingChatMessage)
}
