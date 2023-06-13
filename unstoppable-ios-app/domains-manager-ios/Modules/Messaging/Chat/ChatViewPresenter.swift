//
//  ChatViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import Foundation

@MainActor
protocol ChatViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: ChatViewController.Item)
    func willDisplayItem(_ item: ChatViewController.Item)
    
    func didTypeText(_ text: String)
    func didPressSendText(_ text: String)
}

@MainActor
final class ChatViewPresenter {
    
    private weak var view: ChatViewProtocol?
    private let chat: MessagingChatDisplayInfo
    private let domain: DomainDisplayInfo
    private let fetchLimit: Int = 30
    private var messages: [MessagingChatMessageDisplayInfo] = []
    private var chatState: ChatContentState = .upToDate
    private var isLoadingMore = false
    
    init(view: ChatViewProtocol,
         chat: MessagingChatDisplayInfo,
         domain: DomainDisplayInfo) {
        self.view = view
        self.chat = chat
        self.domain = domain
    }
}

// MARK: - ChatViewPresenterProtocol
extension ChatViewPresenter: ChatViewPresenterProtocol {
    func viewDidLoad() {
        appContext.messagingService.addListener(self)
        setupTitle()
        setupPlaceholder()
        loadAndShowData()
    }
    
    func didSelectItem(_ item: ChatViewController.Item) {
        
    }
    
    func willDisplayItem(_ item: ChatViewController.Item) {
        let message = item.message
        guard let messageIndex = messages.firstIndex(where: { $0.id == message.id }) else {
            Debugger.printFailure("Failed to find will display message with id \(message.id) in the list", critical: true)
            return }
        
        if messageIndex >= (messages.count - 7) {
            switch chatState {
            case .hasUnloadedMessagesBefore(let message):
                loadMoreMessagesBefore(message: message)
            case .upToDate:
                return
            case .hasUnreadMessagesAfter:
                return
            }
        }
        
        if !message.isRead {
            messages[messageIndex].isRead = true
            try? appContext.messagingService.markMessage(message, isRead: true)
        }
    }
    
    func didTypeText(_ text: String) {
        
    }
    
    func didPressSendText(_ text: String) {
        guard !text.trimmedSpaces.isEmpty else { return }
        
        view?.setInputText("")
        sendTextMesssage(text)
    }
}

// MARK: - MessagingServiceListener
extension ChatViewPresenter: MessagingServiceListener {
    nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
        Task { @MainActor in
            switch messagingDataType {
            case .chats, .channels:
                return
            case .messagesAdded(let messages, let chatId):
                if chatId == chat.id {
                    self.addMessages(messages)
                    checkIfUpToDate()
                    showData(animated: true, scrollToBottomAnimated: true)
                }
            case .messageUpdated(let updatedMessage, let newMessage):
                if updatedMessage.chatId == chat.id,
                   let i = self.messages.firstIndex(where: { $0.id == updatedMessage.id }) {
                    self.messages[i] = newMessage
                    checkIfUpToDate()
                    showData(animated: true)
                }
            case .messagesRemoved(let messages, let chatId):
                if chatId == chat.id {
                    let removedIds = messages.map { $0.id }
                    self.messages = self.messages.filter({ !removedIds.contains($0.id) })
                    checkIfUpToDate()
                    showData(animated: true)
                }
            }
        }
    }
}

// MARK: - Private functions
private extension ChatViewPresenter {
    func loadAndShowData() {
        Task {
            do {
                isLoadingMore = true
                showData(animated: false, scrollToBottomAnimated: false)
                let messagesBefore = try await appContext.messagingService.getMessagesForChat(chat,
                                                                                              before: nil,
                                                                                              limit: fetchLimit)
                addMessages(messagesBefore)
                
                if !messages.first!.isRead,
                   let firstReadMessage = messages.first(where: { $0.isRead }) {
                    self.chatState = .hasUnreadMessagesAfter(message: firstReadMessage)
                } else {
                    checkIfUpToDate()
                }
                
                switch chatState {
                case .upToDate, .hasUnloadedMessagesBefore:
                    showData(animated: false, scrollToBottomAnimated: false)
                case .hasUnreadMessagesAfter(let message):
                    messages = messages.filter({ $0.isRead })
                    showData(animated: false, scrollToBottomAnimated: false)
                    let unreadMessages = try await appContext.messagingService.getMessagesForChat(chat,
                                                                                                  after: message,
                                                                                                  limit: fetchLimit)
                    addMessages(unreadMessages)
                    showData(animated: true)
                }
                isLoadingMore = false
            } catch {
                view?.showAlertWith(error: error, handler: nil) // TODO: - Handle error
            }
        }
    }
    
    func loadMoreMessagesBefore(message: MessagingChatMessageDisplayInfo) {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        Task {
            do {
                let unreadMessages = try await appContext.messagingService.getMessagesForChat(chat,
                                                                                              before: message,
                                                                                              limit: fetchLimit)
                addMessages(unreadMessages)
                checkIfUpToDate()
                isLoadingMore = false
                showData(animated: false)
            } catch {
                view?.showAlertWith(error: error, handler: nil) // TODO: - Handle error
                isLoadingMore = false
            }
        }
    }
    
    func checkIfUpToDate() {
        guard !messages.isEmpty else {
            chatState = .upToDate
            return
        }
         if messages.last!.isFirstInChat {
            self.chatState = .upToDate
        } else {
            self.chatState = .hasUnloadedMessagesBefore(message: messages.last!)
        }
    }
    
    func addMessages(_ messages: [MessagingChatMessageDisplayInfo]) {
        for message in messages {
            if let i = self.messages.firstIndex(where: { $0.id == message.id }) {
                self.messages[i] = message
            } else {
                self.messages.append(message)
            }
        }
        
        self.messages.sort(by: { $0.time > $1.time })
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
        
        let groupedMessages = [Date : [MessagingChatMessageDisplayInfo]].init(grouping: messages, by: { $0.time.dayStart })
        let sortedDates = groupedMessages.keys.sorted(by: { $0 < $1 })
        
        for date in sortedDates {
            let messages = groupedMessages[date] ?? []
            let title = MessageDateFormatter.formatMessagesSectionDate(date)
            snapshot.appendSections([.messages(title: title)])
            snapshot.appendItems(messages.sorted(by: { $0.time < $1.time }).map({ createSnapshotItemFrom(message: $0) }))
        }
        
        view?.applySnapshot(snapshot, animated: animated, completion: completion)
    }
    
    func createSnapshotItemFrom(message: MessagingChatMessageDisplayInfo) -> ChatViewController.Item {
        switch message.type {
        case .text(let textMessageDisplayInfo):
            return .textMessage(configuration: .init(message: message, textMessageDisplayInfo: textMessageDisplayInfo, actionCallback: { [weak self] action in
                self?.handleChatMessageAction(action, forMessage: message)
            }))
        }
    }
    
    func setupTitle() {
        switch chat.type {
        case .private(let chatDetails):
            let otherUser = chatDetails.otherUser
            if let domainName = otherUser.domainName {
                view?.setTitleOfType(.domainName(domainName))
            } else {
                view?.setTitleOfType(.walletAddress(otherUser.wallet))
            }
        case .group(let groupDetails):
            return // <GROUP_CHAT> Not supported for now
        }
    }
    
    func setupPlaceholder() {
        view?.setPlaceholder(String.Constants.chatInputPlaceholderAsDomain.localized(domain.name))
    }
    
    func handleChatMessageAction(_ action: ChatViewController.ChatMessageAction,
                                 forMessage message: MessagingChatMessageDisplayInfo) {
        switch action {
        case .resend:
            Task { try? await appContext.messagingService.resendMessage(message) }
        case .delete:
            do {
                try appContext.messagingService.deleteMessage(message)
                if let i = messages.firstIndex(where: { $0.id == message.id }) {
                    messages.remove(at: i)
                    showData(animated: true)
                }
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
        }
    }
}

// MARK: - Send message
private extension ChatViewPresenter {
    func sendTextMesssage(_ text: String) {
        let textTypeDetails = MessagingChatMessageTextTypeDisplayInfo(text: text,
                                                                      encryptedText: text)
        let messageType = MessagingChatMessageDisplayType.text(textTypeDetails)
        sendMessageOfType(messageType)
    }
    
    func sendMessageOfType(_ type: MessagingChatMessageDisplayType) {
        Task {
            do {
                let newMessage = try await appContext.messagingService.sendMessage(type, in: chat)
                messages.insert(newMessage, at: 0)
                showData(animated: true, scrollToBottomAnimated: true)
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
        }
    }
}

// MARK: - Private methods
private extension ChatViewPresenter {
    enum ChatContentState {
        case upToDate
        case hasUnloadedMessagesBefore(message: MessagingChatMessageDisplayInfo)
        case hasUnreadMessagesAfter(message: MessagingChatMessageDisplayInfo)
    }
}
