//
//  MessagingAPIServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

protocol MessagingAPIServiceProtocol {
    var serviceIdentifier: MessagingServiceIdentifier { get }
    var capabilities: MessagingServiceCapabilities { get }

    // User profile
    func getUserFor(wallet: WalletEntity) async throws -> MessagingChatUserProfile
    func createUser(for wallet: WalletEntity) async throws -> MessagingChatUserProfile
    func updateUserProfile(_ user: MessagingChatUserProfile,
                           name: String,
                           avatar: String) async throws
    
    // Chats
    func getChatsListForUser(_ user: MessagingChatUserProfile,
                             page: Int,
                             limit: Int) async throws -> [MessagingChat]
    func getChatRequestsForUser(_ user: MessagingChatUserProfile,
                                page: Int,
                                limit: Int) async throws -> [MessagingChat]
    func getCommunitiesListForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingChat]
    func getCachedBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) -> MessagingPrivateChatBlockingStatus
    func getBlockingStatusForChat(_ chat: MessagingChat) async throws -> MessagingPrivateChatBlockingStatus
    func setUser(in chat: MessagingChat,
                 blocked: Bool,
                 by user: MessagingChatUserProfile) async throws
    func setUser(_ otherUser: MessagingChatUserDisplayInfo,
                 in groupChat: MessagingChat,
                 blocked: Bool,
                 by user: MessagingChatUserProfile) async throws
    func block(chats: [MessagingChat],
               by user: MessagingChatUserProfile) async throws
    func isAbleToContactAddress(_ address: String,
                                by user: MessagingChatUserProfile) async throws -> Bool
    
    // Messages
    func getMessagesForChat(_ chat: MessagingChat,
                            before message: MessagingChatMessage?,
                            cachedMessages: [MessagingChatMessage],
                            fetchLimit: Int,
                            isRead: Bool,
                            for user: MessagingChatUserProfile,
                            filesService: MessagingFilesServiceProtocol) async throws -> [MessagingChatMessage]
    func loadRemoteContentFor(_ message: MessagingChatMessage,
                              user: MessagingChatUserProfile,
                              serviceData: Data,
                              filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessageDisplayType
    func isMessagesEncryptedIn(chatType: MessagingChatType) async -> Bool
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChat,
                     by user: MessagingChatUserProfile,
                     filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessage
    func sendFirstMessage(_ messageType: MessagingChatMessageDisplayType,
                          to userInfo: MessagingChatUserDisplayInfo,
                          by user: MessagingChatUserProfile,
                          filesService: MessagingFilesServiceProtocol) async throws -> (MessagingChat, MessagingChatMessage)
    
    func makeChatRequest(_ chat: MessagingChat,
                         approved: Bool,
                         by user: MessagingChatUserProfile) async throws
    func leaveGroupChat(_ chat: MessagingChat,
                        by user: MessagingChatUserProfile) async throws
    func joinCommunityChat(_ communityChat: MessagingChat,
                           by user: MessagingChatUserProfile) async throws -> MessagingChat
    func leaveCommunityChat(_ communityChat: MessagingChat,
                            by user: MessagingChatUserProfile) async throws -> MessagingChat
}

struct MessagingServiceCapabilities {
    let canContactWithoutProfile: Bool
    let canBlockUsers: Bool
    let isSupportChatsListPagination: Bool
    let isRequiredToReloadLastMessage: Bool
}
