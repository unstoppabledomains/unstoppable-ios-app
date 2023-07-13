//
//  MessagingStorageServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

protocol MessagingStorageServiceProtocol {
    // User Profile
    func getUserProfileFor(domain: DomainItem) throws -> MessagingChatUserProfile
    func getUserProfileWith(userId: String) throws -> MessagingChatUserProfile
    func saveUserProfile(_ profile: MessagingChatUserProfile) async
    
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
    func deleteMessage(_ message: MessagingChatMessageDisplayInfo)
    func markMessage(_ message: MessagingChatMessageDisplayInfo,
                     isRead: Bool) throws
    func markSendingMessagesAsFailed()
    
    // Chats
    func getChatsFor(profile: MessagingChatUserProfile,
                     decrypter: MessagingContentDecrypterService) async throws -> [MessagingChat]
    func getChatWith(id: String,
                     decrypter: MessagingContentDecrypterService) async -> MessagingChat?
    func getChatsWithIdContaining(_ value: String,
                                  decrypter: MessagingContentDecrypterService) async -> [MessagingChat]
    func saveChats(_ chats: [MessagingChat]) async
    func replaceChat(_ chatToReplace: MessagingChat,
                     with newChat: MessagingChat) async throws
    func deleteChat(_ chat: MessagingChat)
    
    // User info
    func saveMessagingUserInfo(_ info: MessagingChatUserDisplayInfo) async
    
    // Channels
    func getChannelsFor(profile: MessagingChatUserProfile) async throws -> [MessagingNewsChannel]
    func getChannelsWith(address: String) async throws -> [MessagingNewsChannel]
    func saveChannels(_ channels: [MessagingNewsChannel],
                      for profile: MessagingChatUserProfile) async
    func replaceChannel(_ channelToReplace: MessagingNewsChannel,
                        with newChat: MessagingNewsChannel) async throws
    func deleteChannel(_ channel: MessagingNewsChannel)
    
    // Channels Feed
    func getChannelsFeedFor(channel: MessagingNewsChannel,
                            page: Int,
                            limit: Int) async throws -> [MessagingNewsChannelFeed]
    func saveChannelsFeed(_ feed: [MessagingNewsChannelFeed],
                          in channel: MessagingNewsChannel) async
    func markFeedItem(_ feedItem: MessagingNewsChannelFeed,
                      isRead: Bool) throws
    
    // Clear
    func clearAllDataOf(profile: MessagingChatUserProfile) async
}
