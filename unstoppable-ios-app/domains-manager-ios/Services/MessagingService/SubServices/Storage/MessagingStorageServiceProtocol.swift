//
//  MessagingStorageServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

protocol MessagingStorageServiceProtocol {
    // Messages
    func getMessagesFor(chat: MessagingChatDisplayInfo,
                        decrypter: MessagingContentDecrypterService) async throws -> [MessagingChatMessage]
    func getMessagesFor(chat: MessagingChatDisplayInfo,
                        decrypter: MessagingContentDecrypterService,
                        before message: MessagingChatMessageDisplayInfo?,
                        limit: Int) async throws -> [MessagingChatMessage]
    func getMessagesFor(chat: MessagingChatDisplayInfo,
                        decrypter: MessagingContentDecrypterService,
                        after message: MessagingChatMessageDisplayInfo,
                        limit: Int) async throws -> [MessagingChatMessage]
    func getMessageWith(id: String,
                        in chat: MessagingChatDisplayInfo,
                        decrypter: MessagingContentDecrypterService) async -> MessagingChatMessage?
    func saveMessages(_ messages: [MessagingChatMessage]) async
    func replaceMessage(_ messageToReplace: MessagingChatMessage,
                        with newMessage: MessagingChatMessage) async throws
    
    // Chats
    func getChatsFor(decrypter: MessagingContentDecrypterService,
                     wallet: String) async throws -> [MessagingChat]
    func getChatWith(id: String,
                     decrypter: MessagingContentDecrypterService) async -> MessagingChat?
    func saveChats(_ chats: [MessagingChat]) async
    
    // User info
    func saveMessagingUserInfo(_ info: MessagingChatUserDisplayInfo) async
    
    // Channels
    func getChannelsFor(wallet: String) async throws -> [MessagingNewsChannel]
    func saveChannels(_ channels: [MessagingNewsChannel],
                      for wallet: String) async
    
    // Channels Feed
    func getChannelsFeedFor(channel: MessagingNewsChannel) async throws -> [MessagingNewsChannelFeed]
    func saveChannelsFeed(_ feed: [MessagingNewsChannelFeed],
                          in channel: MessagingNewsChannel) async
}
