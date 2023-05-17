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
    private var domains: [DomainDisplayInfo] = []
    private var selectedDomain: DomainDisplayInfo?
    
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
            await loadDomains()
            var snapshot = ChatsListSnapshot()
           
            
            guard let selectedDomain else { return }
            
            let channels = await appContext.messagingService.getChannelsForDomain(selectedDomain)
            
            snapshot.appendSections([.channels])
            snapshot.appendItems(channels.map({ ChatsListViewController.Item.channel(configuration: .init(channelType: $0)) }))
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
    
    func loadDomains() async {
        if domains.isEmpty {
            domains = await appContext.dataAggregatorService.getDomainsDisplayInfo()
            selectedDomain = domains.first
        }
    }
}
