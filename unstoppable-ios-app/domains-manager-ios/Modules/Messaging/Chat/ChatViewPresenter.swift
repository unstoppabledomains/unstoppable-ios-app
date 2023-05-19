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
        setupTitle()
        showData(completion: { [weak self] in self?.view?.scrollToTheBottom(animated: false) })
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
    func showData(completion: EmptyCallback? = nil) {
        Task {
            var snapshot = ChatSnapshot()
            
            let messages = await appContext.messagingService.getMessagesForChannel(channelType)
            
            snapshot.appendSections([.messages])
            snapshot.appendItems(messages.map({ createSnapshotItemFrom(message: $0) }))
            
            view?.applySnapshot(snapshot, animated: true, completion: completion)
        }
    }
    
    func createSnapshotItemFrom(message: ChatMessageType) -> ChatViewController.Item {
        switch message {
        case .text(let message):
            return .textMessage(configuration: .init(message: message))
        }
    }
    
    func setupTitle() {
        Task {
            switch channelType {
            case .domain(let channel):
                let domainName = channel.domainName
                let pfpInfo = await appContext.udDomainsService.loadPFP(for: domainName)
                view?.setTitleOfType(.domainName(domainName, pfpInfo: pfpInfo))
            }
        }
    }
}
