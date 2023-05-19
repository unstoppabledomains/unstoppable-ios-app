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
        UDVibration.buttonTap.vibrate()
        switch item {
        case .domainSelection(let configuration):
            guard !configuration.isSelected else { return }
            
            selectedDomain = configuration.domain
            showData()
        case .channel(let configuration):
            return
        }
    }
}

// MARK: - Private functions
private extension ChatsListViewPresenter {
    func showData() {
        Task {
            await loadDomains()
            var snapshot = ChatsListSnapshot()
           
            
            guard let selectedDomain else { return }
            
            snapshot.appendSections([.domainsSelection])
            for domain in domains {
                let unreadMessagesCount = await appContext.messagingService.getNumberOfUnreadMessagesInChannelsForDomain(domain)
                let item = ChatsListViewController.Item.domainSelection(configuration: .init(domain: domain,
                                                                                             isSelected: domain.isSameEntity(selectedDomain),
                                                                                             unreadMessagesCount: unreadMessagesCount))
                snapshot.appendItems([item])
            }
            
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
