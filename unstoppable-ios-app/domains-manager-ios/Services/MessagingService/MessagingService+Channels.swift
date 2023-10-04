//
//  MessagingService+Channels.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.10.2023.
//

import Foundation

extension MessagingService {
    func getOrFetchChannelOfCurrentUserWithAddress(_ channelAddress: String,
                                                   isCurrentUserSubscribed: Bool) async throws -> MessagingNewsChannel? {
        guard let currentUser else { return nil }
        
        let apiService = try getDefaultAPIService()
        let profile = try storageService.getUserProfileWith(userId: currentUser.id,
                                                            serviceIdentifier: apiService.serviceIdentifier)
        let cachedChannels = try await storageService.getChannelsFor(profile: profile)
        if let cachedChannel = cachedChannels.first(where: { $0.channel == channelAddress }) {
            return cachedChannel
        }
        
        let channels = try await channelsApiService.getChannelsWithIds([channelAddress],
                                                                       isCurrentUserSubscribed: isCurrentUserSubscribed,
                                                                       user: profile)
        return channels.first
    }
    
    func refreshChannelsMetadata(_ channels: [MessagingNewsChannel],
                                 storedChannels: [MessagingNewsChannel]) async -> [MessagingNewsChannel] {
        var updatedChannels = [MessagingNewsChannel]()
        
        await withTaskGroup(of: MessagingNewsChannel.self, body: { group in
            for channel in channels {
                group.addTask {
                    if var lastMessage = try? await self.channelsApiService.getFeedFor(channel: channel,
                                                                                       page: 1,
                                                                                       limit: 1,
                                                                                       isRead: false).first {
                        var updatedChannel = channel
                        if let storedChannel = storedChannels.first(where: { $0.id == channel.id }),
                           let storedLastMessage = storedChannel.lastMessage,
                           storedLastMessage.id == lastMessage.id {
                            lastMessage.isRead = storedLastMessage.isRead
                        } else {
                            lastMessage.isRead = true
                            await self.storageService.saveChannelsFeed([lastMessage],
                                                                       in: channel)
                        }
                        updatedChannel.lastMessage = lastMessage
                        return updatedChannel
                    } else {
                        return channel
                    }
                }
            }
            
            for await channel in group {
                updatedChannels.append(channel)
            }
        })
        
        return updatedChannels
    }
    
    func refreshChannelsForProfile(_ profile: MessagingChatUserProfile) {
        Task {
            dataRefreshManager.startUpdatingChannels(for: profile.displayInfo)
            let startTime = Date()
            do {
                let storedChannels = try await storageService.getChannelsFor(profile: profile)
                
                async let channelsTask = Utilities.catchingFailureAsyncTask(asyncCatching: {
                    try await channelsApiService.getSubscribedChannelsForUser(profile)
                }, defaultValue: [])
                async let spamChannelsTask = Utilities.catchingFailureAsyncTask(asyncCatching: {
                    try await channelsApiService.getSpamChannelsForUser(profile)
                }, defaultValue: [])
                
                let (channels, spamChannels) = await (channelsTask, spamChannelsTask)
                let channelsIds = Set(channels.map { $0.id })
                let allChannels = channels + spamChannels.filter { !channelsIds.contains($0.id) }
                
                let updatedChats = await refreshChannelsMetadata(allChannels, storedChannels: storedChannels).sortedByLastMessage()
                
                await storageService.saveChannels(updatedChats, for: profile)
                
                let updatedStoredChannels = try await storageService.getChannelsFor(profile: profile)
                notifyListenersChangedDataType(.channels(updatedStoredChannels, profile: profile.displayInfo))
                Debugger.printTimeSensitiveInfo(topic: .Messaging,
                                                "to refresh channels list for \(profile.wallet)",
                                                startDate: startTime,
                                                timeout: 3)
            } catch {
                Debugger.printFailure("Did fail to refresh channels list for \(profile.wallet)")
            }
            dataRefreshManager.stopUpdatingChannels(for: profile.displayInfo)
        }
    }
}

// MARK: - Private methods
private extension MessagingService {
 
}
