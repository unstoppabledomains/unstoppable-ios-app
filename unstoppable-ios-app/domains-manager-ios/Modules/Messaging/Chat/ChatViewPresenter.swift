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
    
    func didTypeText(_ text: String)
    func didPressSendText(_ text: String)
}

@MainActor
final class ChatViewPresenter {
    
    private weak var view: ChatViewProtocol?
    private let chat: MessagingChatDisplayInfo
    private let domain: DomainDisplayInfo
    private let fetchLimit: Int = 20
    private var messages: [MessagingChatMessageDisplayInfo] = []
    
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
        setupTitle()
        setupPlaceholder()
        loadAndShowData()
    }
    
    func didSelectItem(_ item: ChatViewController.Item) {
        
    }
    
    func didTypeText(_ text: String) {
        
    }
    
    func didPressSendText(_ text: String) {
        guard !text.trimmedSpaces.isEmpty else { return }
        
        view?.setInputText("")
        sendTextMesssage(text)
    }
}

// MARK: - Private functions
private extension ChatViewPresenter {
    func loadAndShowData() {
        Task {
            do {
                messages = try await appContext.messagingService.getMessagesForChat(chat, fetchLimit: 30)
                showData(animated: false, scrollToBottomAnimated: false)
            } catch {
                view?.showAlertWith(error: error, handler: nil) // TODO: - Handle error
            }
        }
    }
    
    func showData(animated: Bool, scrollToBottomAnimated: Bool) {
        showData(animated: animated, completion: { [weak self] in
            DispatchQueue.main.async {
                self?.view?.scrollToTheBottom(animated: scrollToBottomAnimated)
            }
        })
    }
    
    func showData(animated: Bool, completion: EmptyCallback? = nil) {
        var snapshot = ChatSnapshot()
        
        let groupedMessages = [Date : [MessagingChatMessageDisplayInfo]].init(grouping: messages, by: { $0.time.dayStart })
        let sortedDates = groupedMessages.keys.sorted(by: { $0 < $1 })
        
        for date in sortedDates {
            let messages = groupedMessages[date] ?? []
            let title = MessageDateFormatter.formatMessagesSectionDate(date)
            snapshot.appendSections([.messages(title: title)])
            snapshot.appendItems(messages.map({ createSnapshotItemFrom(message: $0) }))
        }
        
        view?.applySnapshot(snapshot, animated: animated, completion: completion)
    }
    
    func createSnapshotItemFrom(message: MessagingChatMessageDisplayInfo) -> ChatViewController.Item {
        switch message.type {
        case .text(let textMessageDisplayInfo):
            return .textMessage(configuration: .init(message: message, textMessageDisplayInfo: textMessageDisplayInfo))
        }
    }
    
    func setupTitle() {
        switch chat.type {
        case .private(let chatDetails):
            let otherUser = chatDetails.otherUser
            if let domainName = otherUser.domain?.name {
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
}

// MARK: - Send message
private extension ChatViewPresenter {
    func sendTextMesssage(_ text: String) {
        let textTypeDetails = MessagingChatMessageTextTypeDisplayInfo(text: text)
        let messageType = MessagingChatMessageDisplayType.text(textTypeDetails)
        sendMessageOfType(messageType)
    }
    
    func sendMessageOfType(_ type: MessagingChatMessageDisplayType) {
        do {
            // TODO: - Probably should expect all messages from listener notification
            let newMessage = try appContext.messagingService.sendMessage(type, in: chat)
            messages.append(newMessage)
            showData(animated: true, scrollToBottomAnimated: true)
        } catch {
            view?.showAlertWith(error: error, handler: nil)
        }
    }
}
