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
    func deleteMessage(_ message: MessagingChatMessageDisplayInfo) throws
    func markMessage(_ message: MessagingChatMessageDisplayInfo,
                     isRead: Bool) throws
    func markSendingMessagesAsFailed()
    
    // Chats
    func getChatsFor(profile: MessagingChatUserProfile,
                     decrypter: MessagingContentDecrypterService) async throws -> [MessagingChat]
    func getChatWith(id: String,
                     decrypter: MessagingContentDecrypterService) async -> MessagingChat?
    func saveChats(_ chats: [MessagingChat]) async
    func replaceChat(_ chatToReplace: MessagingChat,
                     with newChat: MessagingChat) async throws
    
    // User info
    func saveMessagingUserInfo(_ info: MessagingChatUserDisplayInfo) async
    
    // Channels
    func getChannelsFor(profile: MessagingChatUserProfile) async throws -> [MessagingNewsChannel]
    func saveChannels(_ channels: [MessagingNewsChannel],
                      for profile: MessagingChatUserProfile) async
    
    // Channels Feed
    func getChannelsFeedFor(channel: MessagingNewsChannel) async throws -> [MessagingNewsChannelFeed]
    func saveChannelsFeed(_ feed: [MessagingNewsChannelFeed],
                          in channel: MessagingNewsChannel) async
}
