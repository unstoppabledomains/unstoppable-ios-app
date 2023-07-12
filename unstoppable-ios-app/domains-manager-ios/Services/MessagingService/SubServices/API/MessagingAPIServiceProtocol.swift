//
//  MessagingAPIServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

protocol MessagingAPIServiceProtocol {
    // User profile
    func getUserFor(domain: DomainItem) async throws -> MessagingChatUserProfile
    func createUser(for domain: DomainItem) async throws -> MessagingChatUserProfile
    
    // Chats
    func getChatsListForUser(_ user: MessagingChatUserProfile,
                             page: Int,
                             limit: Int) async throws -> [MessagingChat]
    func getChatRequestsForUser(_ user: MessagingChatUserProfile,
                                page: Int,
                                limit: Int) async throws -> [MessagingChat]
    func getBlockingStatusForChat(_ chat: MessagingChat) async throws -> MessagingPrivateChatBlockingStatus
    func setUser(in chat: MessagingChat,
                 blocked: Bool,
                 by user: MessagingChatUserProfile) async throws
    
    // Messages
    func getMessagesForChat(_ chat: MessagingChat,
                            options: MessagingAPIServiceLoadMessagesOptions,
                            fetchLimit: Int,
                            for user: MessagingChatUserProfile) async throws -> [MessagingChatMessage]
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChat,
                     by user: MessagingChatUserProfile) async throws -> MessagingChatMessage
    func sendFirstMessage(_ messageType: MessagingChatMessageDisplayType,
                          to userInfo: MessagingChatUserDisplayInfo,
                          by user: MessagingChatUserProfile) async throws -> (MessagingChat, MessagingChatMessage)
    
    func makeChatRequest(_ chat: MessagingChat,
                         approved: Bool,
                         by user: MessagingChatUserProfile) async throws
    func leaveGroupChat(_ chat: MessagingChat,
                        by user: MessagingChatUserProfile) async throws
    
    // Channels
    func getSubscribedChannelsForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel]
    func getSpamChannelsForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel]
    func getNotificationsInboxFor(wallet: HexAddress,
                                  page: Int,
                                  limit: Int,
                                  isSpam: Bool) async throws -> [MessagingNewsChannelFeed]
    func getFeedFor(channel: MessagingNewsChannel,
                    page: Int,
                    limit: Int) async throws -> [MessagingNewsChannelFeed]
    func searchForChannels(page: Int,
                           limit: Int,
                           searchKey: String,
                           for user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel]
    func setChannel(_ channel: MessagingNewsChannel,
                    subscribed: Bool,
                    by user: MessagingChatUserProfile) async throws
}

enum MessagingAPIServiceLoadMessagesOptions {
    case `default`
    case before(message: MessagingChatMessage)
    case after(message: MessagingChatMessage)
}
