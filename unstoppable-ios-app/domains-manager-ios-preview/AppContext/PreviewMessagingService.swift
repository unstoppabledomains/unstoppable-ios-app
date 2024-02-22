//
//  PreviewMessagingService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

final class MessagingService: MessagingServiceProtocol {
    var defaultServiceIdentifier: MessagingServiceIdentifier = .xmtp
    
    func canContactWithoutProfileIn(newConversation newConversationDescription: MessagingChatNewConversationDescription) -> Bool {
        true
    }
    
    func canBlockUsers(in chat: MessagingChatDisplayInfo) -> Bool {
        true
    }
    
    func isAbleToContactUserIn(newConversation newConversationDescription: MessagingChatNewConversationDescription, by user: MessagingChatUserProfileDisplayInfo) async throws -> Bool {
        true
    }
    
    func fetchWalletsAvailableForMessaging() -> [WalletEntity] {
        MockEntitiesFabric.Wallet.mockEntities() 
    }
    
    func createUserMessagingProfile(for wallet: WalletEntity) async throws -> MessagingChatUserProfileDisplayInfo {
        .init(id: "1", wallet: wallet.address, serviceIdentifier: .xmtp)
    }
    
    func isCommunitiesEnabled(for messagingProfile: MessagingChatUserProfileDisplayInfo) async -> Bool {
        true
    }
    
    func createCommunityProfile(for messagingProfile: MessagingChatUserProfileDisplayInfo) async throws {
        
    }
    
    func setCurrentUser(_ userProfile: MessagingChatUserProfileDisplayInfo?) {
        
    }
    
    func isUpdatingUserData(_ userProfile: MessagingChatUserProfileDisplayInfo) -> Bool {
        false
    }
    
    func isNewMessagesAvailable() async throws -> Bool {
        false
    }
    
    func makeChatRequest(_ chat: MessagingChatDisplayInfo, approved: Bool) async throws {
        
    }
    
    func getBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) async throws -> MessagingPrivateChatBlockingStatus {
        .unblocked
    }
    
    func setUser(in chatType: MessagingBlockUserInChatType, blocked: Bool) async throws {
        
    }
    
    func block(chats: [MessagingChatDisplayInfo]) async throws {
        
    }
    
    func leaveGroupChat(_ chat: MessagingChatDisplayInfo) async throws {
        
    }
    
    func joinCommunityChat(_ communityChat: MessagingChatDisplayInfo) async throws -> MessagingChatDisplayInfo {
        throw NSError()
    }
    
    func leaveCommunityChat(_ communityChat: MessagingChatDisplayInfo) async throws -> MessagingChatDisplayInfo {
        throw NSError()
    }
    
    func getMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo, before message: MessagingChatMessageDisplayInfo?, cachedOnly: Bool, limit: Int) async throws -> [MessagingChatMessageDisplayInfo] {
        await Task.sleep(seconds: 0.2)
        return MockEntitiesFabric.Messaging.createMessagesForUITesting(isFixedID: false)
    }
    
    func loadRemoteContentFor(_ message: MessagingChatMessageDisplayInfo, in chat: MessagingChatDisplayInfo) async throws -> MessagingChatMessageDisplayInfo {
//        throw NSError()
        message
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType, isEncrypted: Bool, in chat: MessagingChatDisplayInfo) async throws -> MessagingChatMessageDisplayInfo {
        throw NSError()
    }
    
    func isMessagesEncryptedIn(conversation: MessagingChatConversationState) async throws -> Bool {
        true
    }
    
    func sendFirstMessage(_ messageType: MessagingChatMessageDisplayType, to newConversationDescription: MessagingChatNewConversationDescription, by profile: MessagingChatUserProfileDisplayInfo) async throws -> (MessagingChatDisplayInfo, MessagingChatMessageDisplayInfo) {
        throw NSError()
    }
    
    func resendMessage(_ message: MessagingChatMessageDisplayInfo, in chatDisplayInfo: MessagingChatDisplayInfo) async throws {
        
    }
    
    func deleteMessage(_ message: MessagingChatMessageDisplayInfo, in chatDisplayInfo: MessagingChatDisplayInfo) async throws {
        
    }
    
    func markMessage(_ message: MessagingChatMessageDisplayInfo, isRead: Bool, wallet: String) throws {
        
    }
    
    func decryptedContentURLFor(message: MessagingChatMessageDisplayInfo) async -> URL? {
        nil
    }
    
    func isMessage(_ message: MessagingChatMessageDisplayInfo, belongTo profile: MessagingChatUserProfileDisplayInfo) async -> Bool {
        false
    }
    
    func getChannelsForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel] {
        MockEntitiesFabric.Messaging.createChannelsForUITesting()
    }
    
    func getFeedFor(channel: MessagingNewsChannel, cachedOnly: Bool, page: Int, limit: Int) async throws -> [MessagingNewsChannelFeed] {
        MockEntitiesFabric.Messaging.createChannelsFeedForUITesting()
    }
    
    func markFeedItem(_ feedItem: MessagingNewsChannelFeed, isRead: Bool, in channel: MessagingNewsChannel) throws {
        
    }
    
    func setChannel(_ channel: MessagingNewsChannel, subscribed: Bool, by user: MessagingChatUserProfileDisplayInfo) async throws {
        
    }
    
    func isAddressIsSpam(_ address: String) async throws -> Bool {
        false
    }
    
    func addListener(_ listener: MessagingServiceListener) {
        
    }
    
    func removeListener(_ listener: MessagingServiceListener) {
        
    }
    
    func logout() { }
    
    func getLastUsedMessagingProfile(among givenWallets: [WalletEntity]?) async -> MessagingChatUserProfileDisplayInfo? {
        nil
    }
    
    func getUserMessagingProfile(for wallet: WalletEntity) async throws -> MessagingChatUserProfileDisplayInfo {
        .init(id: "1", wallet: wallet.address, serviceIdentifier: .xmtp)
    }
    
    func getChatsListForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingChatDisplayInfo] {
        MockEntitiesFabric.Messaging.createChatsForUITesting()
    }
    
    func searchForUsersWith(searchKey: String) async throws -> [MessagingChatUserDisplayInfo] { [] }
    func getCachedBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) -> MessagingPrivateChatBlockingStatus
    { .unblocked }
    func searchForChannelsWith(page: Int,
                               limit: Int,
                               searchKey: String,
                               for user: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel] { [] }
}
