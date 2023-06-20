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
    private let channel: MessagingNewsChannel
    private let fetchLimit: Int = 30
    private var feed: [MessagingNewsChannelFeed] = []
    private var chatState: ChatContentState = .upToDate
    private var isLoadingMessages = false

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
//        guard case .channelFeed(let configuration) = item else {
//            return
//        }
//        let displayFeed = configuration.feed
//        
//        guard let displayFeedIndex = feed.firstIndex(where: { $0.id == displayFeed.id }) else {
//            Debugger.printFailure("Failed to find will display feed with id \(displayFeed.id) in the list", critical: true)
//            return }
//        
//        if !displayFeed.isRead {
//            feed[displayFeedIndex].isRead = true
//            try? appContext.messagingService.markMessage(displayFeed, isRead: true, wallet: chat.thisUserDetails.wallet)
//        }
//        
//        if displayFeedIndex >= (feed.count - Constants.numberOfUnreadMessagesBeforePrefetch) {
//            switch chatState {
//            case .hasUnloadedMessagesBefore(let message):
//                loadMoreMessagesBefore(message: message)
//            case .upToDate:
//                return
//            case .hasUnreadMessagesAfter:
//                return
//            }
//        }
    }
}

// MARK: - MessagingServiceListener
extension ChannelViewPresenter: MessagingServiceListener {
    nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
        Task { @MainActor in
            switch messagingDataType {
            case .chats, .channels, .messagesAdded, .messageUpdated, .messagesRemoved:
                return
            }
        }
    }
}

// MARK: - Private methods
private extension ChannelViewPresenter {
    func setupUI() {
        view?.setTitleOfType(.channel(channel))
        view?.setUIState(.viewChannel)
    }
    
    func loadAndShowData() {
        Task {
//            do {
//                isLoadingMessages = true
//                view?.setLoading(active: true)
//                let messagesBefore = try await appContext.messagingService.getch
//                addMessages(messagesBefore)
//
//                if !messages.first!.isRead,
//                   let firstReadMessage = messages.first(where: { $0.isRead }) {
//                    self.chatState = .hasUnreadMessagesAfter(message: firstReadMessage)
//                } else {
//                    checkIfUpToDate()
//                }
//
//                switch chatState {
//                case .upToDate, .hasUnloadedMessagesBefore:
//                    showData(animated: false, scrollToBottomAnimated: false)
//                case .hasUnreadMessagesAfter(let message):
//                    let unreadMessages = try await appContext.messagingService.getMessagesForChat(chat,
//                                                                                                  after: message,
//                                                                                                  limit: fetchLimit)
//                    addMessages(unreadMessages)
//                    showData(animated: false, completion: {
//                        if let message = unreadMessages.last {
//                            let item = self.createSnapshotItemFrom(message: message)
//                            self.view?.scrollToItem(item, animated: false)
//                        }
//                    })
//                    checkIfUpToDate()
//                }
//                DispatchQueue.main.async {
//                    self.view?.setLoading(active: false)
//                    self.updateUIForChatApprovedState()
//                }
//                isLoadingMessages = false
//            } catch {
//                view?.showAlertWith(error: error, handler: nil)
//            }
        }
    }

    func loadMoreMessagesBefore(message: MessagingNewsChannelFeed) {
//        guard !isLoadingMessages,
//              case .existingChat(let chat) = conversationState else { return }
//
//        isLoadingMessages = true
//        Task {
//            do {
//                let unreadMessages = try await appContext.messagingService.getMessagesForChat(chat,
//                                                                                              before: message,
//                                                                                              limit: fetchLimit)
//                addMessages(unreadMessages)
//                checkIfUpToDate()
//                isLoadingMessages = false
//                showData(animated: false)
//            } catch {
//                view?.showAlertWith(error: error, handler: nil) // TODO: - Handle error
//                isLoadingMessages = false
//            }
//        }
    }
    
    func checkIfUpToDate() {
//        guard !feed.isEmpty else {
//            chatState = .upToDate
//            return
//        }
//        if feed.last!.isFirstInChat {
//            self.chatState = .upToDate
//        } else {
//            self.chatState = .hasUnloadedMessagesBefore(message: feed.last!)
//        }
    }
    
    func addMessages(_ feed: [MessagingNewsChannelFeed]) {
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
    
    func handleChatMessageAction(_ action: ChatViewController.ChatMessageAction,
                                 forFeedItem feedItem: MessagingNewsChannelFeed) {
        switch action {
        case .resend, .delete:
            return
        }
    }
    
}

// MARK: - Private methods
private extension ChannelViewPresenter {
    enum ChatContentState {
        case upToDate
        case hasUnloadedMessagesBefore(message: MessagingNewsChannelFeed)
        case hasUnreadMessagesAfter(message: MessagingNewsChannelFeed)
    }
}
