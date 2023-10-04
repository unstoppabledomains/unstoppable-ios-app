//
//  MessagingServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

//MARK: - This is draft implementation to make UI done.
protocol MessagingServiceProtocol {
    // Capabilities
    func canContactWithoutProfile(using messagingService: MessagingServiceIdentifier) -> Bool
    func canBlockUsers(in chat: MessagingChatDisplayInfo) -> Bool
    func isAbleToContactAddress(_ address: String,
                                by user: MessagingChatUserProfileDisplayInfo) async throws -> Bool
    func fetchWalletsAvailableForMessaging() async -> [WalletDisplayInfo]
    func getLastUsedMessagingProfile(among givenWallets: [WalletDisplayInfo]?) async -> MessagingChatUserProfileDisplayInfo?
    
    // User
    func getUserMessagingProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo
    func createUserMessagingProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo
    func isCommunitiesEnabled(for messagingProfile: MessagingChatUserProfileDisplayInfo) async -> Bool
    func setCurrentUser(_ userProfile: MessagingChatUserProfileDisplayInfo?)
    func isUpdatingUserData(_ userProfile: MessagingChatUserProfileDisplayInfo) -> Bool
    func isNewMessagesAvailable() async throws -> Bool
    
    // Chats list
    func getChatsListForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingChatDisplayInfo]
    func makeChatRequest(_ chat: MessagingChatDisplayInfo, approved: Bool) async throws
    func getCachedBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) -> MessagingPrivateChatBlockingStatus
    func getBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) async throws -> MessagingPrivateChatBlockingStatus
    func setUser(in chat: MessagingChatDisplayInfo,
                 blocked: Bool) async throws
    func leaveGroupChat(_ chat: MessagingChatDisplayInfo) async throws
    
    // Messages
    func getMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo,
                            before message: MessagingChatMessageDisplayInfo?,
                            cachedOnly: Bool,
                            limit: Int) async throws -> [MessagingChatMessageDisplayInfo]
    func loadRemoteContentFor(_ message: MessagingChatMessageDisplayInfo,
                              in chat: MessagingChatDisplayInfo) async throws -> MessagingChatMessageDisplayInfo
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     isEncrypted: Bool,
                     in chat: MessagingChatDisplayInfo) async throws -> MessagingChatMessageDisplayInfo
    func isMessagesEncryptedIn(conversation: MessagingChatConversationState) async throws -> Bool
    func sendFirstMessage(_ messageType: MessagingChatMessageDisplayType,
                          to newConversationDescription: MessagingChatNewConversationDescription,
                          by profile: MessagingChatUserProfileDisplayInfo) async throws -> (MessagingChatDisplayInfo, MessagingChatMessageDisplayInfo)
    func resendMessage(_ message: MessagingChatMessageDisplayInfo,
                       in chatDisplayInfo: MessagingChatDisplayInfo) async throws
    func deleteMessage(_ message: MessagingChatMessageDisplayInfo,
                       in chatDisplayInfo: MessagingChatDisplayInfo) async throws
    func markMessage(_ message: MessagingChatMessageDisplayInfo,
                     isRead: Bool,
                     wallet: String) throws
    func decryptedContentURLFor(message: MessagingChatMessageDisplayInfo) async -> URL?
    
    // Channels
    func getChannelsForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel]
    func getFeedFor(channel: MessagingNewsChannel,
                    cachedOnly: Bool,
                    page: Int,
                    limit: Int) async throws -> [MessagingNewsChannelFeed]
    func markFeedItem(_ feedItem: MessagingNewsChannelFeed,
                      isRead: Bool,
                      in channel: MessagingNewsChannel) throws
    func setChannel(_ channel: MessagingNewsChannel,
                    subscribed: Bool,
                    by user: MessagingChatUserProfileDisplayInfo) async throws
    
    // Search
    func searchForUsersWith(searchKey: String) async throws -> [MessagingChatUserDisplayInfo]
    func searchForChannelsWith(page: Int,
                               limit: Int,
                               searchKey: String,
                               for user: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel]
    
    // Listeners
    func addListener(_ listener: MessagingServiceListener)
    func removeListener(_ listener: MessagingServiceListener)
}

protocol MessagingServiceListener: AnyObject {
    func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType)
}

final class MessagingListenerHolder: Equatable {

    weak var listener: MessagingServiceListener?

    init(listener: MessagingServiceListener) {
        self.listener = listener
    }

    static func == (lhs: MessagingListenerHolder, rhs: MessagingListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }

        return lhsListener === rhsListener
    }

}

enum MessagingDataType {
    case chats(_ chats: [MessagingChatDisplayInfo], profile: MessagingChatUserProfileDisplayInfo)
    case channels(_ channels: [MessagingNewsChannel], profile: MessagingChatUserProfileDisplayInfo)
    case messagesAdded(_ messages: [MessagingChatMessageDisplayInfo], chatId: String, userId: String)
    case messageUpdated(_ updatedMessage: MessagingChatMessageDisplayInfo, newMessage: MessagingChatMessageDisplayInfo)
    case messagesRemoved(_ messages: [MessagingChatMessageDisplayInfo], chatId: String)
    case messageReadStatusUpdated(_ message: MessagingChatMessageDisplayInfo, numberOfUnreadMessagesInSameChat: Int)
    case channelFeedAdded(_ feed: MessagingNewsChannelFeed, channelId: String)
    case refreshOfUserProfile(_ userProfile: MessagingChatUserProfileDisplayInfo, isInProgress: Bool)
    case totalUnreadMessagesCountUpdated(_ havingUnreadMessages: Bool)
    
    var debugDescription: String {
        switch self {
        case .chats(let chats, let profile):
            return "Chats: \(chats.count) for \(profile.id)"
        case .channels(let channels, let profile):
            return "Channels: \(channels.count) for \(profile.id)"
        case .messagesAdded(let messages, let chatId, let userId):
            return "Messages added: \(messages.map { $0.id }) in \(chatId) for \(userId)"
        case .messageUpdated(let updatedMessage, let newMessage):
            return "Message updated from \(updatedMessage.id) to \(newMessage.id)"
        case .messagesRemoved(let messages, let chatId):
            return "Messages removed: \(messages.map { $0.id }) in \(chatId)"
        case .messageReadStatusUpdated(let message, let numberOfUnreadMessagesInSameChat):
            return "Message read status update: \(message.id). numberOfUnreadMessagesInSameChat: \(numberOfUnreadMessagesInSameChat)"
        case .channelFeedAdded(let feed, let channelId):
            return "Channel feed added: \(feed.id) in \(channelId)"
        case .refreshOfUserProfile(let profile, let isInProgress):
            return "Refresh of profile \(profile.id) in progress: \(isInProgress)"
        case .totalUnreadMessagesCountUpdated(let havingUnreadMessages):
            return "TotalUnreadMessagesCountUpdated to havingUnreadMessages: \(havingUnreadMessages)"
        }
    }
}
