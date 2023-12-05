//
//  PreviewMessagingService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

protocol MessagingServiceProtocol {
    func getLastUsedMessagingProfile(among givenWallets: [WalletDisplayInfo]?) async -> MessagingChatUserProfileDisplayInfo?

    func getUserMessagingProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo

    func getChatsListForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingChatDisplayInfo]
    func searchForUsersWith(searchKey: String) async throws -> [MessagingChatUserDisplayInfo]
    func getCachedBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) -> MessagingPrivateChatBlockingStatus
    func searchForChannelsWith(page: Int,
                               limit: Int,
                               searchKey: String,
                               for user: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel]
}

final class MessagingService: MessagingServiceProtocol {
    func getLastUsedMessagingProfile(among givenWallets: [WalletDisplayInfo]?) async -> MessagingChatUserProfileDisplayInfo? {
        nil
    }
    
    func getUserMessagingProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo {
        .init(id: "", wallet: domain.ownerWallet ?? "", serviceIdentifier: .xmtp)
    }
    
    func getChatsListForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingChatDisplayInfo] {
        []
    }
    
    func searchForUsersWith(searchKey: String) async throws -> [MessagingChatUserDisplayInfo] { [] }
    func getCachedBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) -> MessagingPrivateChatBlockingStatus
    { .unblocked }
    func searchForChannelsWith(page: Int,
                               limit: Int,
                               searchKey: String,
                               for user: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel] { [] }
}
