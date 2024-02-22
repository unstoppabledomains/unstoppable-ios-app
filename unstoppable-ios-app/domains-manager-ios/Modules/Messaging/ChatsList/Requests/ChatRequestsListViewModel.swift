//
//  ChatRequestsListViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

@MainActor
final class ChatRequestsListViewModel: ObservableObject, ViewAnalyticsLogger {
    
    private let profile: MessagingChatUserProfileDisplayInfo

    @Published var dataType: ChatRequestsListView.DataType
    @Published private var spamWalletsList: Set<String> = []
    @Published private var verifiedWalletsList: Set<String> = []
    @Published private(set) var isLoading = false
    @Published var selectedChats: Set<MessagingChatDisplayInfo> = []
    @Published var error: Error?
    @Published var isEditing = false

    private let serialQueue = DispatchQueue(label: "ChatsRequestsListViewPresenter.queue")
    
    private var router: HomeTabRouter

    
    var analyticsName: Analytics.ViewName {
        switch dataType {
        case .chatRequests:
            return .chatRequestsList
        case .channelsSpam:
            return .chatChannelsSpamList
        }
    }
    
    init(dataType: ChatRequestsListView.DataType,
         profile: MessagingChatUserProfileDisplayInfo,
         router: HomeTabRouter) {
        self.dataType = dataType
        self.profile = profile
        self.router = router
        appContext.messagingService.addListener(self)
        checkForSpamChats()
    }
    
}

extension ChatRequestsListViewModel {
    func openChat(_ chat: MessagingChatDisplayInfo) {
        router.chatTabNavPath.append(.chat(profile: profile, conversationState: .existingChat(chat)))
    }
    
    func openChannel(_ channel: MessagingNewsChannel) {
        router.chatTabNavPath.append(.channel(profile: profile, channel: channel))
    }
    
    func blockButtonPressed() {
        guard !selectedChats.isEmpty,
              case .chatRequests(let chats) = dataType else { return }
        
        isEditing = false
        Task {
            isLoading = true
            do {
                try await appContext.messagingService.block(chats: Array(selectedChats))
                if chats.count == selectedChats.count {
                    router.chatTabNavPath.removeLast()
                }
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func selectAllButtonPressed() {
        if case .chatRequests(let chats) = dataType {
            selectedChats = Set(chats)
        }
    }
}

// MARK: - MessagingServiceListener
extension ChatRequestsListViewModel: MessagingServiceListener {
    nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
        Task { @MainActor in
            switch messagingDataType {
            case .chats(let chats, let profile):
                if profile.id == self.profile.id,
                   case .chatRequests = dataType {
                    let requests = chats.unblockedOnly().requestsOnly()
                    self.dataType = .chatRequests(requests)
                    checkForSpamChats()
                }
            case .channels(let channels, let profile):
                if profile.id == self.profile.id,
                   case .channelsSpam = dataType {
                    let requests = channels.filter { !$0.isCurrentUserSubscribed }
                    self.dataType = .channelsSpam(requests)
                }
            case .messageReadStatusUpdated(let message, let numberOfUnreadMessagesInSameChat):
                switch dataType {
                case .chatRequests(var chatsList):
                    if let i = chatsList.firstIndex(where: { $0.id == message.chatId }) {
                        chatsList[i].unreadMessagesCount = numberOfUnreadMessagesInSameChat
                        self.dataType = .chatRequests(chatsList)
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
private extension ChatRequestsListViewModel {
    func getPrivateChatUserWallet(_ chat: MessagingChatDisplayInfo) -> String? {
        switch chat.type {
        case .private(let details):
            return details.otherUser.wallet
        case .group, .community:
            return nil
        }
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
    
    func isChatIsSpam(_ chat: MessagingChatDisplayInfo) -> Bool {
        if let wallet = getPrivateChatUserWallet(chat) {
            return spamWalletsList.contains(wallet)
        }
        return false
    }
}
