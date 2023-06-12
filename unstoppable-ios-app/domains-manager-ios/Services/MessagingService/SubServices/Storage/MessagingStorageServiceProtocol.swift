//
//  MessagingStorageServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

protocol MessagingStorageServiceProtocol {
    // Messages
    func getMessages(decrypter: MessagingContentDecrypterService,
                     wallet: String) async throws -> [MessagingChatMessage]
    func saveMessages(_ messages: [MessagingChatMessage]) async
    
    // Chats
    func getChatsFor(decrypter: MessagingContentDecrypterService,
                     wallet: String) async throws -> [MessagingChat]
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
