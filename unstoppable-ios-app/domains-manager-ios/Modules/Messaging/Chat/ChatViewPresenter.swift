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
        showData(animated: false, completion: { [weak self] in
            DispatchQueue.main.async {
                self?.view?.scrollToTheBottom(animated: false)
            }
        })
    }
    
    func didSelectItem(_ item: ChatViewController.Item) {
        
    }
    
    func didTypeText(_ text: String) {
        
    }
    
    func didPressSendText(_ text: String) {
        
    }
}

// MARK: - Private functions
private extension ChatViewPresenter {
    func showData(animated: Bool, completion: EmptyCallback? = nil) {
        Task {
            do {
                var snapshot = ChatSnapshot()
                
                let messages = try await appContext.messagingService.getMessagesForChat(chat, fetchLimit: 30)
                let groupedMessages = [Date : [MessagingChatMessageDisplayInfo]].init(grouping: messages, by: { $0.time.dayStart })
                let sortedDates = groupedMessages.keys.sorted(by: { $0 < $1 })
                
                for date in sortedDates {
                    let messages = groupedMessages[date] ?? []
                    let title = MessageDateFormatter.formatMessagesSectionDate(date)
                    snapshot.appendSections([.messages(title: title)])
                    snapshot.appendItems(messages.map({ createSnapshotItemFrom(message: $0) }))
                }
                
                view?.applySnapshot(snapshot, animated: animated, completion: completion)
            } catch {
                Debugger.printFailure(error.localizedDescription) // TODO: - Handle error
            }
        }
    }
    
    func createSnapshotItemFrom(message: MessagingChatMessageDisplayInfo) -> ChatViewController.Item {
        switch message.type {
        case .text(let textMessageDisplayInfo):
            return .textMessage(configuration: .init(message: message, textMessageDisplayInfo: textMessageDisplayInfo))
        }
    }
    
    func setupTitle() {
//        switch chat {
//        case .domain(let channel):
//            let domainName = channel.domainName
//            view?.setTitleOfType(.domainName(domainName))
//        }
    }
    
    func setupPlaceholder() {
        view?.setPlaceholder(String.Constants.chatInputPlaceholderAsDomain.localized(domain.name))
    }
}
