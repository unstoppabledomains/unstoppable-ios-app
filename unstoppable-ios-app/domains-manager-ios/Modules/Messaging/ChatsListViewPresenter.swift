//
//  ChatsListViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

protocol ChatsListViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: ChatsListViewController.Item)
}

final class ChatsListViewPresenter {
    private weak var view: ChatsListViewProtocol?
    
    init(view: ChatsListViewProtocol) {
        self.view = view
    }
}

// MARK: - ChatsListViewPresenterProtocol
extension ChatsListViewPresenter: ChatsListViewPresenterProtocol {
    func viewDidLoad() {
        showData()
    }
    
    func didSelectItem(_ item: ChatsListViewController.Item) {
        
    }
}

// MARK: - Private functions
private extension ChatsListViewPresenter {
    func showData() {
        Task {
            var snapshot = ChatsListSnapshot()
           
            // Fill snapshot
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
}
