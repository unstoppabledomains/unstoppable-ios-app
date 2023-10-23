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
    private var selectedChats: [MessagingChatDisplayInfo] = []
    private var spamWalletsList: Set<String> = []
    private var verifiedWalletsList: Set<String> = []
    private let serialQueue = DispatchQueue(label: "ChatsRequestsListViewPresenter.queue")

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
        checkForSpamChats()
    }
    
    func didSelectItem(_ item: ChatsListViewController.Item, mode: ChatsListViewController.Mode) {
        UDVibration.buttonTap.vibrate()
        switch item {
        case .chat(let configuration):
            let chat = configuration.chat
            switch mode {
            case .default:
                openChat(chat)
            case .editing:
                if let i = selectedChats.firstIndex(where: { $0.id == chat.id }) {
                    selectedChats.remove(at: i)
                } else {
                    selectedChats.append(chat)
                }
            }
            showData()
        case .channel(let configuration):
            openChannel(configuration.channel)
        default:
            return
        }
    }
    
    func actionButtonPressed() {
        guard !selectedChats.isEmpty,
              case .chatRequests(let chats) = dataType else { return }
        
        Task {
            view?.setActivityIndicator(active: true)
            do {
                try await appContext.messagingService.block(chats: selectedChats)
                if chats.count == selectedChats.count {
                    view?.cNavigationController?.popViewController(animated: true)
                }
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
            view?.setActivityIndicator(active: false)
        }
    }
    
    func editingModeActionButtonPressed(_ action: ChatsList.EditingModeAction) {
        switch action {
        case .selectAll:
            if case .chatRequests(let chats) = dataType {
                selectedChats = chats
            }
        case .cancel:
            selectedChats = []
        case .edit:
            return
        }
        showData()
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
                    checkForSpamChats()
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
                snapshot.appendItems([.emptyState(configuration: .init(dataType: .chats, isRequestsList: true))])
                view?.cNavigationController?.viewControllers.removeAll(where: { $0 == view })
            } else {
                snapshot.appendSections([.listItems(title: nil)])
                snapshot.appendItems(requests.map({ request in
                    let isSelected = selectedChats.first(where: { $0.id == request.id }) != nil
                    let isSpam = isChatIsSpam(request)
                    return ChatsListViewController.Item.chat(configuration: .init(chat: request,
                                                                                  isSelected: isSelected,
                                                                                  isSpam: isSpam))
                }))
            }
        case .channelsSpam(let requests):
            snapshot.appendSections([.listItems(title: nil)])
            snapshot.appendItems(requests.map({ ChatsListViewController.Item.channel(configuration: .init(channel: $0)) }))
        }
        
        view?.applySnapshot(snapshot, animated: true)
    }
    
    func getPrivateChatUserWallet(_ chat: MessagingChatDisplayInfo) -> String? {
        switch chat.type {
        case .private(let details):
            return details.otherUser.wallet
        case .group:
            return nil
        }
    }
    
    func isChatIsSpam(_ chat: MessagingChatDisplayInfo) -> Bool {
        if let wallet = getPrivateChatUserWallet(chat) {
            return spamWalletsList.contains(wallet)
        }
        return false
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
    
    func checkForSpamChats() {
        Task {
            switch dataType {
            case .chatRequests(let chats):
                await withTaskGroup(of: Void.self) { group in
                    for chat in chats {
                        if let wallet = getPrivateChatUserWallet(chat),
                           !verifiedWalletsList.contains(wallet) {
                            group.addTask {
                                try? await self.verifyWallet(wallet)
                                return Void()
                            }
                        }
                    }
                    
                    for await _ in group {
                        
                    }
                }
                showData()
            case .channelsSpam:
                return
            }
        }
    }
    
    func verifyWallet(_ wallet: String) async throws {
        let isSpam = try await appContext.messagingService.isAddressIsSpam(wallet)
        serialQueue.sync {
            if isSpam {
                spamWalletsList.insert(wallet)
            }
            verifiedWalletsList.insert(wallet)
        }
    }
}

// MARK: - Open methods
extension ChatsRequestsListViewPresenter {
    enum DataType {
        case chatRequests([MessagingChatDisplayInfo])
        case channelsSpam([MessagingNewsChannel])
    }
}
