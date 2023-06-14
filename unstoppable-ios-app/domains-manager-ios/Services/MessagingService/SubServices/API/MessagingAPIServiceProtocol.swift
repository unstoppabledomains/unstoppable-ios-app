//
//  MessagingAPIServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

protocol MessagingAPIServiceProtocol {
    // Chats
    func getChatsListForWallet(_ wallet: HexAddress,
                               page: Int,
                               limit: Int) async throws -> [MessagingChat]
    func getChatRequestsForWallet(_ wallet: HexAddress,
                                  page: Int,
                                  limit: Int) async throws -> [MessagingChat]
    
    // Messages
    func getMessagesForChat(_ chat: MessagingChat,
                            options: MessagingAPIServiceLoadMessagesOptions,
                            fetchLimit: Int) async throws -> [MessagingChatMessage]
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChat) async throws -> MessagingChatMessage
    func makeChatRequest(_ chat: MessagingChat, approved: Bool) async throws
    
    // Channels
    func getSubscribedChannelsFor(wallet: HexAddress) async throws -> [MessagingNewsChannel]
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
