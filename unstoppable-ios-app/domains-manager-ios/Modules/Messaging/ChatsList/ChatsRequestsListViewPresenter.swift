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
    private let dataType: DataType
    
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
    func viewDidLoad() {
        appContext.messagingService.addListener(self)
    }
    
    func viewDidAppear() {
        view?.setState(.requestsList)
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
                if profile.id == self.profile.id {
//                   chatsList != chats {
//                    chatsList = chats
                    showData()
                }
            case .channels(let channels, let profile):
            if profile.id == self.profile.id {
//                    self.channels = channels
                    showData()
                }
            case .messageUpdated, .messagesRemoved, .messagesAdded:
                return
            }
        }
    }
}

// MARK: - Private methods
private extension ChatsRequestsListViewPresenter {
    func showData() {
        var snapshot = ChatsListSnapshot()
        
        snapshot.appendSections([.listItems(title: nil)])
        
        switch dataType {
        case .chatRequests(let requests):
            snapshot.appendItems(requests.map({ ChatsListViewController.Item.chat(configuration: .init(chat: $0)) }))
        case .channelsRequests(let requests):
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
        case channelsRequests([MessagingNewsChannel])
    }
}
