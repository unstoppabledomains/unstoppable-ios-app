//
//  MessagingChannelsAPIServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation

protocol MessagingChannelsAPIServiceProtocol {
    func getSubscribedChannelsForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel]
    func getSpamChannelsForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel]
    func getFeedFor(channel: MessagingNewsChannel,
                    page: Int,
                    limit: Int,
                    isRead: Bool) async throws -> [MessagingNewsChannelFeed]
    func searchForChannels(page: Int,
                           limit: Int,
                           searchKey: String,
                           for user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel]
    func setChannel(_ channel: MessagingNewsChannel,
                    subscribed: Bool,
                    by user: MessagingChatUserProfile) async throws
}
