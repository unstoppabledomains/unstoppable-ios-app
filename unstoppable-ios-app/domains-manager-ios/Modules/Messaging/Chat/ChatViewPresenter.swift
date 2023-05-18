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
}

@MainActor
final class ChatViewPresenter {
    
    private weak var view: ChatViewProtocol?
    private let channelType: ChatChannelType
    
    init(view: ChatViewProtocol,
         channelType: ChatChannelType) {
        self.view = view
        self.channelType = channelType
    }
}

// MARK: - ChatViewPresenterProtocol
extension ChatViewPresenter: ChatViewPresenterProtocol {
    func viewDidLoad() {
        showData()
    }
    
    func didSelectItem(_ item: ChatViewController.Item) {
        
    }
}

// MARK: - Private functions
private extension ChatViewPresenter {
    func showData() {
        Task {
            var snapshot = ChatSnapshot()
            
            let messages = await appContext.messagingService.getMessagesForChannel(channelType)
            
            snapshot.appendSections([.messages])
            snapshot.appendItems(messages.map({ createSnapshotItemFrom(message: $0) }))
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
    
    func createSnapshotItemFrom(message: ChatMessageType) -> ChatViewController.Item {
        switch message {
        case .text(let message):
            return .textMessage(configuration: .init(message: message))
        }
    }
}
