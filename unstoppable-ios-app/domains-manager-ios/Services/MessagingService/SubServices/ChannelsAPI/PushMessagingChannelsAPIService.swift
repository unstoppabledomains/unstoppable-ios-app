//
//  PushMessagingChannelsAPIService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import Push

final class PushMessagingChannelsAPIService {
    
    private let pushRESTService = PushRESTAPIService()
    private let pushHelper = PushServiceHelper()
    private let messagingHelper = MessagingAPIServiceHelper()
    
}

// MARK: - MessagingChannelsAPIServiceProtocol
extension PushMessagingChannelsAPIService: MessagingChannelsAPIServiceProtocol {
    func getSubscribedChannelsForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel] {
        let subscribedChannelsIds = try await pushRESTService.getSubscribedChannelsIds(for: user.wallet)
        
        return try await getChannelsWithIds(Set(subscribedChannelsIds), isCurrentUserSubscribed: true, user: user)
    }
    
    func getSpamChannelsForUser(_ user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel] {
        let spamChannelIds = try await pushRESTService.getSpamChannelsIds(for: user.wallet)
        
        return try await getChannelsWithIds(Set(spamChannelIds), isCurrentUserSubscribed: false, user: user)
    }
    
    private func getChannelsWithIds(_ channelIds: Set<String>,
                                    isCurrentUserSubscribed: Bool,
                                    user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel] {
        guard !channelIds.isEmpty else { return [] }
        
        var channels = [PushChannel?]()
        await withTaskGroup(of: PushChannel?.self, body: { group in
            for id in channelIds {
                group.addTask {
                    try? await self.pushRESTService.getChannelDetails(for: id)
                }
            }
            
            for await channel in group {
                channels.append(channel)
            }
        })
        
        return channels.compactMap({ $0 }).map({ PushEntitiesTransformer.convertPushChannelToMessagingChannel($0,
                                                                                                              isCurrentUserSubscribed: isCurrentUserSubscribed,
                                                                                                              isSearchResult: false,
                                                                                                              userId: user.id) })
    }
    
    func getFeedFor(channel: MessagingNewsChannel,
                    page: Int,
                    limit: Int,
                    isRead: Bool) async throws -> [MessagingNewsChannelFeed] {
        let feed = try await pushRESTService.getChannelFeedForUser(channel.userId,
                                                                   in: channel.channel,
                                                                   page: page,
                                                                   limit: limit)
        
        return feed.map({ PushEntitiesTransformer.convertPushInboxToChannelFeed($0,isRead: isRead) })
    }
    
    func searchForChannels(page: Int,
                           limit: Int,
                           searchKey: String,
                           for user: MessagingChatUserProfile) async throws -> [MessagingNewsChannel] {
        guard !searchKey.trimmedSpaces.isEmpty else { return [] }
        let channels = try await pushRESTService.searchForChannels(page: page, limit: limit, query: searchKey)
        
        return channels.compactMap({ $0 }).map({ PushEntitiesTransformer.convertPushChannelToMessagingChannel($0,
                                                                                                              isCurrentUserSubscribed: false,
                                                                                                              isSearchResult: true,
                                                                                                              userId: user.id) })
    }
    
    func setChannel(_ channel: MessagingNewsChannel,
                    subscribed: Bool,
                    by user: MessagingChatUserProfile) async throws {
        
        let domain = try await messagingHelper.getAnyDomainItem(for: user.normalizedWallet)
        let env = pushHelper.getCurrentPushEnvironment()
        
        let subscribeOptions = Push.PushChannel.SubscribeOption(signer: domain,
                                                                channelAddress: channel.channel,
                                                                env: env)
        if subscribed {
            _ = try await Push.PushChannel.subscribe(option: subscribeOptions)
        } else {
            _ = try await Push.PushChannel.unsubscribe(option: subscribeOptions)
        }
    }
}
