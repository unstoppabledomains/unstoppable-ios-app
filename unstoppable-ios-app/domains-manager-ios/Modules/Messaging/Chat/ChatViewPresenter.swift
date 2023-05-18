//
//  ChatViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import Foundation

protocol ChatViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: ChatViewController.Item)
}

final class ChatViewPresenter {
    
    private weak var view: ChatViewProtocol?
    private let channel: ChatChannel
    
    init(view: ChatViewProtocol,
         channel: ChatChannel) {
        self.view = view
        self.channel = channel
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
           
            // Fill snapshot
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
}
