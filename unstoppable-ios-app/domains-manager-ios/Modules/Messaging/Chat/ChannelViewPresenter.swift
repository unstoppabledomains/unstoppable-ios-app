//
//  ChannelViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.06.2023.
//

import Foundation

@MainActor
final class ChannelViewPresenter {
    
    private weak var view: ChatViewProtocol?
    private let profile: MessagingChatUserProfileDisplayInfo
    private let fetchLimit: Int = 30
    private var channel: MessagingNewsChannel
    private var feed: [MessagingNewsChannelFeed] = []
    private var isLoadingFeed = false
    private var currentPage: Int = 1

    init(view: ChatViewProtocol,
         profile: MessagingChatUserProfileDisplayInfo,
         channel: MessagingNewsChannel) {
        self.view = view
        self.profile = profile
        self.channel = channel
    }
    
}

// MARK: - ChatViewPresenterProtocol
extension ChannelViewPresenter: ChatViewPresenterProtocol {
    func viewDidLoad() {
        appContext.messagingService.addListener(self)
        view?.setUIState(.loading)
        setupUI()
        loadAndShowData()
    }
    
    func didSelectItem(_ item: ChatViewController.Item) {
        
    }
    
    func willDisplayItem(_ item: ChatViewController.Item) {
        guard case .channelFeed(let configuration) = item else {
            return
        }
        let displayFeed = configuration.feed

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
    
    func infoButtonPressed() {
        Task {
            guard let view else { return }
            
            do {
                try await appContext.pullUpViewService.showMessagingChannelInfoPullUp(channel: channel, in: view)
                await view.dismissPullUpMenu()
                view.openLink(.generic(url: channel.url.absoluteString))
            } catch { }
        }
    }
    
    func approveButtonPressed() {
        guard !channel.isCurrentUserSubscribed else { return }
        Task {
            view?.setLoading(active: true)
            do {
                try await appContext.messagingService.setChannel(channel,
                                                                 subscribed: true,
                                                                 by: profile)
                channel.isCurrentUserSubscribed = true
                setupUI()
                try await loadAndAddFeed(for: 1)
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
            view?.setLoading(active: false)
        }
    }
}

// MARK: - MessagingServiceListener
extension ChannelViewPresenter: MessagingServiceListener {
    nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
        Task { @MainActor in
            switch messagingDataType {
            case .channels(let channels, let profile):
                if profile.id == self.profile.id,
                   let channel = channels.first(where: { $0.id == self.channel.id }) {
                    if self.channel.lastMessage?.id != channel.lastMessage?.id {
                        self.channel = channel
                        try await loadAndAddFeed(for: 1)
                        loadAndShowData()
                    } else {
                        self.channel = channel
                    }
                }
            case .chats, .messagesAdded, .messageUpdated, .messagesRemoved:
                return
            }
        }
    }
}

// MARK: - Private methods
private extension ChannelViewPresenter {
    func setupUI() {
        view?.setTitleOfType(.channel(channel))
        if channel.isCurrentUserSubscribed {
            view?.setUIState(.viewChannel)
        } else {
            view?.setUIState(.joinChannel)
        }
    }
    
    func loadAndShowData() {
        Task {
            do {
                isLoadingFeed = true
                view?.setLoading(active: true)
                let feed = try await loadAndAddFeed(for: currentPage)

                if !feed.isEmpty,
                   !feed[0].isRead,
                   let firstReadFeedItem = feed.first(where: { $0.isRead }) {
                    showData(animated: false, completion: {
                        let item = self.createSnapshotItemFrom(feedItem: firstReadFeedItem)
                        self.view?.scrollToItem(item, animated: false)
                    })
                } else {
                    showData(animated: false, scrollToBottomAnimated: false)
                }

                self.view?.setLoading(active: false)
                isLoadingFeed = false
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
        }
    }
    
    @discardableResult
    func loadAndAddFeed(for page: Int) async throws -> [MessagingNewsChannelFeed] {
        let feed = try await appContext.messagingService.getFeedFor(channel: channel,
                                                                    page: page,
                                                                    limit: fetchLimit)
        addFeed(feed)
        return feed
    }

    func loadMoreFeed() {
        guard !isLoadingFeed else { return }

        isLoadingFeed = true
        Task {
            do {
                let newPage = currentPage + 1
                try await loadAndAddFeed(for: newPage)
                currentPage = newPage
                isLoadingFeed = false
                showData(animated: false)
            } catch {
                view?.showAlertWith(error: error, handler: nil) // TODO: - Handle error
                isLoadingFeed = false
            }
        }
    }
    
    func addFeed(_ feed: [MessagingNewsChannelFeed]) {
        for feedItem in feed {
            if let i = self.feed.firstIndex(where: { $0.id == feedItem.id }) {
                self.feed[i] = feedItem
            } else {
                self.feed.append(feedItem)
            }
        }
        
        self.feed.sort(by: { $0.time > $1.time })
    }
    
    func showData(animated: Bool, scrollToBottomAnimated: Bool) {
        showData(animated: animated, completion: { [weak self] in
            DispatchQueue.main.async {
                self?.view?.scrollToTheBottom(animated: scrollToBottomAnimated)
            }
        })
    }
    
    @MainActor
    func showData(animated: Bool, completion: EmptyCallback? = nil) {
        var snapshot = ChatSnapshot()
        
        if feed.isEmpty {
            view?.setScrollEnabled(false)
            snapshot.appendSections([.emptyState])
            snapshot.appendItems([.emptyState]) // TODO: - Specify it is empty state for feed
        } else {
            view?.setScrollEnabled(true)
            let groupedFeed = [Date : [MessagingNewsChannelFeed]].init(grouping: feed, by: { $0.time.dayStart })
            let sortedDates = groupedFeed.keys.sorted(by: { $0 < $1 })
            
            for date in sortedDates {
                let feed = groupedFeed[date] ?? []
                let title = MessageDateFormatter.formatMessagesSectionDate(date)
                snapshot.appendSections([.messages(title: title)])
                snapshot.appendItems(feed.sorted(by: { $0.time < $1.time }).map({ createSnapshotItemFrom(feedItem: $0) }))
            }
        }
        
        view?.applySnapshot(snapshot, animated: animated, completion: completion)
    }
    
    func createSnapshotItemFrom(feedItem: MessagingNewsChannelFeed) -> ChatViewController.Item {
        .channelFeed(configuration: .init(feed: feedItem, actionCallback: { [weak self] action in
            self?.handleChatMessageAction(action, forFeedItem: feedItem)
        }))
    }
    
    func handleChatMessageAction(_ action: ChatViewController.ChatFeedAction,
                                 forFeedItem feedItem: MessagingNewsChannelFeed) {
        switch action {
        case .learnMore:
            view?.openLink(.generic(url: feedItem.link.absoluteString))
        }
    }
    
}
