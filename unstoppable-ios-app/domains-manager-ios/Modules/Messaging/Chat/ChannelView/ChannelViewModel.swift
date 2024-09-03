//
//  ChannelViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

@MainActor
final class ChannelViewModel: ObservableObject, ViewAnalyticsLogger {
  
    private let profile: MessagingChatUserProfileDisplayInfo
    private let fetchLimit: Int = 20
    @Published private(set) var channel: MessagingNewsChannel
    @Published private(set) var channelState: ChannelView.State = .loading
    @Published private(set) var navActions: [ChannelView.NavAction] = []
    @Published private(set) var scrollToFeed: MessagingNewsChannelFeed?
    @Published private(set) var feed: [MessagingNewsChannelFeed] = []
    @Published private(set) var isLoading = false
    @Published var error: Error?
    
    private var isLoadingFeed = false
    private var currentPage: Int = 1
    var analyticsName: Analytics.ViewName { .channelFeed }

    init(profile: MessagingChatUserProfileDisplayInfo,
         channel: MessagingNewsChannel) {
        self.profile = profile
        self.channel = channel 
        appContext.messagingService.addListener(self)
        channelState = .loading
        loadAndShowData()
    }
    
}

// MARK: - ChatViewPresenterProtocol
extension ChannelViewModel {
    func willDisplayFeed(_ displayFeed: MessagingNewsChannelFeed) {
        guard let displayFeedIndex = feed.firstIndex(where: { $0.id == displayFeed.id }) else {
            Debugger.printFailure("Failed to find will display feed with id \(displayFeed.id) in the list", critical: true)
            return }
        
        if !displayFeed.isRead {
            feed[displayFeedIndex].isRead = true
            try? appContext.messagingService.markFeedItem(displayFeed, isRead: true, in: channel)
        }
        
        if displayFeedIndex >= (feed.count - Constants.numberOfUnreadMessagesBeforePrefetch),
           !feed.last!.isFirstInChannel {
            loadMoreFeed()
        }
    }
    
    func joinButtonPressed() {
        guard !channel.isCurrentUserSubscribed else { return }
        
        setChannel(subscribed: true)
    }
}

// MARK: - MessagingServiceListener
extension ChannelViewModel: MessagingServiceListener {
    nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
        Task { @MainActor in
            switch messagingDataType {
            case .channels(let channels, let profile):
                if profile.id == self.profile.id,
                   let channel = channels.first(where: { $0.id == self.channel.id }) {
                    if self.channel.lastMessage?.id != channel.lastMessage?.id {
                        self.channel = channel
                        try await loadAndAddFeed(forPage: 1)
                        loadAndShowData()
                    } else {
                        self.channel = channel
                    }
                }
            case .channelFeedAdded(let feed, let channelId):
                if channelId == channel.id {
                    addFeed([feed])
                }
            case .chats, .messagesAdded, .messageUpdated, .messagesRemoved, .refreshOfUserProfile, .messageReadStatusUpdated, .totalUnreadMessagesCountUpdated, .userInfoRefreshed, .profileCreated:
                return
            }
        }
    }
}

// MARK: - Private methods
private extension ChannelViewModel {
    func setupChannelActions() {
        var actions: [ChannelView.NavAction] = []
        actions.append(.init(type: .viewInfo, callback: { [weak self] in
            self?.logButtonPressedAnalyticEvents(button: .viewChannelInfo,
                                                 parameters: [.channelName: self?.channel.name ?? ""])
            self?.showChannelInfo()
        }))
        
        if channel.isCurrentUserSubscribed {
            actions.append(.init(type: .leave, callback: { [weak self] in
                self?.logButtonPressedAnalyticEvents(button: .leaveChannel,
                                                     parameters: [.channelName: self?.channel.name ?? ""])
                self?.leaveChannel()
            }))
            channelState = .viewChannel
        } else {
            channelState = .joinChannel
        }
        navActions = actions
    }
    
    func loadAndShowData() {
        Task {
            do {
                isLoadingFeed = true
                isLoading = true
                
                try await loadAndAddFeed(forPage: currentPage, scrollToBottom: true, cachedOnly: true)
                setupChannelActions()
                try await loadAndAddFeed(forPage: currentPage, scrollToBottom: true)
                self.isLoadingFeed = false
                isLoading = false
            } catch {
                self.error = error
            }
        }
    }
    
    @discardableResult
    func loadAndAddFeed(forPage page: Int,
                        scrollToBottom: Bool = false,
                        cachedOnly: Bool = false) async throws -> [MessagingNewsChannelFeed] {
        let feed = try await appContext.messagingService.getFeedFor(channel: channel,
                                                                    cachedOnly: cachedOnly,
                                                                    page: page,
                                                                    limit: fetchLimit)
        if feed.isEmpty,
           !self.feed.isEmpty {
            self.feed[self.feed.count - 1].isFirstInChannel = true
        }
        addFeed(feed, scrollToBottom: scrollToBottom)
        return feed
    }
    
    func loadMoreFeed() {
        guard !isLoadingFeed else { return }
        
        isLoadingFeed = true
        Task {
            do {
                let newPage = currentPage + 1
                try await loadAndAddFeed(forPage: newPage)
                currentPage = newPage
                isLoadingFeed = false
            } catch {
                self.error = error
                isLoadingFeed = false
            }
        }
    }
    
    func addFeed(_ feed: [MessagingNewsChannelFeed],
                 scrollToBottom: Bool = false) {
        for feedItem in feed {
            if let i = self.feed.firstIndex(where: { $0.id == feedItem.id }) {
                self.feed[i] = feedItem
            } else {
                self.feed.append(feedItem)
            }
        }
        
        self.feed.sort(by: { $0.time > $1.time })
        
        if scrollToBottom {
            self.scrollToFeed = feed.first
        }
    }
    
    func setChannel(subscribed: Bool) {
        Task {
            isLoading = true
            do {
                try await appContext.messagingService.setChannel(channel,
                                                                 subscribed: subscribed,
                                                                 by: profile)
                channel.isCurrentUserSubscribed = subscribed
                try await loadAndAddFeed(forPage: 1)
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func showChannelInfo() {
        Task {
            guard let view = appContext.coreAppCoordinator.topVC else { return }
            
            do {
                try await appContext.pullUpViewService.showMessagingChannelInfoPullUp(channel: channel, in: view)
                await view.dismissPullUpMenu()
                view.openLink(.generic(url: channel.url.absoluteString))
            } catch { }
        }
    }
    
    func leaveChannel() {
        setChannel(subscribed: false)
    }
}
