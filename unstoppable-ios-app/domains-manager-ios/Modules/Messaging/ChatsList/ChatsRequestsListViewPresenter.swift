//
//  ChatsRequestsListViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.06.2023.
//

import Foundation

@MainActor
final class ChatsRequestsListViewPresenter {
    
    private weak var view: ChatsListViewProtocol?
    
    private let profile: MessagingChatUserProfileDisplayInfo
    private var dataType: DataType
    
    init(view: ChatsListViewProtocol,
         dataType: DataType,
         profile: MessagingChatUserProfileDisplayInfo) {
        self.view = view
        self.dataType = dataType
        self.profile = profile
    }
}

// MARK: - ChatsListViewPresenterProtocol
extension ChatsRequestsListViewPresenter: ChatsListViewPresenterProtocol {
    var analyticsName: Analytics.ViewName {
        switch dataType {
        case .chatRequests:
            return .chatRequestsList
        case .channelsSpam:
            return .chatChannelsSpamList
        }
    }
    
    func viewDidLoad() {
        appContext.messagingService.addListener(self)
    }
    
    func viewDidAppear() {
        switch dataType {
        case .chatRequests:
            view?.setState(.requestsList(.chats))
        case .channelsSpam:
            view?.setState(.requestsList(.channels))
        }
        showData()
    }
    
    func didSelectItem(_ item: ChatsListViewController.Item) {
        UDVibration.buttonTap.vibrate()
        switch item {
        case .chat(let configuration):
            openChat(configuration.chat)
        case .channel(let configuration):
            openChannel(configuration.channel)
        default:
            return
        }
    }
}

// MARK: - MessagingServiceListener
extension ChatsRequestsListViewPresenter: MessagingServiceListener {
    nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
        Task { @MainActor in
            switch messagingDataType {
            case .chats(let chats, let profile):
                if profile.id == self.profile.id,
                   case .chatRequests = dataType {
                    let requests = chats.unblockedOnly().requestsOnly()
                    self.dataType = .chatRequests(requests)
                    showData()
                }
            case .channels(let channels, let profile):
                if profile.id == self.profile.id,
                   case .channelsSpam = dataType {
                    let requests = channels.filter { !$0.isCurrentUserSubscribed }
                    self.dataType = .channelsSpam(requests)
                    showData()
                }
            case .messageReadStatusUpdated(let message, let numberOfUnreadMessagesInSameChat):
                switch dataType {
                case .chatRequests(var chatsList):
                    if let i = chatsList.firstIndex(where: { $0.id == message.chatId }) {
                        chatsList[i].unreadMessagesCount = numberOfUnreadMessagesInSameChat
                        self.dataType = .chatRequests(chatsList)
                        if numberOfUnreadMessagesInSameChat == 0 {
                            showData()
                        }
                    }
                case .channelsSpam:
                    return
                }
            case .messageUpdated, .messagesRemoved, .messagesAdded, .channelFeedAdded, .refreshOfUserProfile, .totalUnreadMessagesCountUpdated:
                return
            }
        }
    }
}

// MARK: - Private methods
private extension ChatsRequestsListViewPresenter {
    func showData() {
        var snapshot = ChatsListSnapshot()
        
        switch dataType {
        case .chatRequests(let requests):
            if requests.isEmpty {
                snapshot.appendSections([.emptyState])
                snapshot.appendItems([.emptyState(configuration: .emptyData(dataType: .chats, isRequestsList: true))])
                view?.cNavigationController?.viewControllers.removeAll(where: { $0 == view })
            } else {
                snapshot.appendSections([.listItems(title: nil)])
                snapshot.appendItems(requests.map({ ChatsListViewController.Item.chat(configuration: .init(chat: $0)) }))
            }
        case .channelsSpam(let requests):
            snapshot.appendSections([.listItems(title: nil)])
            snapshot.appendItems(requests.map({ ChatsListViewController.Item.channel(configuration: .init(channel: $0)) }))
        }
        
        view?.applySnapshot(snapshot, animated: true)
    }
    
    func openChat(_ chat: MessagingChatDisplayInfo) {
        guard let nav = view?.cNavigationController  else { return }
        
        UDRouter().showChatScreen(profile: profile,
                                  conversationState: .existingChat(chat),
                                  in: nav)
    }
    
    func openChannel(_ channel: MessagingNewsChannel) {
        guard let nav = view?.cNavigationController else { return }
        
        UDRouter().showChannelScreen(profile: profile,
                                     channel: channel,
                                     in: nav)
    }
    
}

// MARK: - Open methods
extension ChatsRequestsListViewPresenter {
    enum DataType {
        case chatRequests([MessagingChatDisplayInfo])
        case channelsSpam([MessagingNewsChannel])
    }
}
