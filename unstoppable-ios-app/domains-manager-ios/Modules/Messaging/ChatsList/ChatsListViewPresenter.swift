//
//  ChatsListViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

@MainActor
protocol ChatsListViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: ChatsListViewController.Item)
}

@MainActor
final class ChatsListViewPresenter {
    
    private weak var view: ChatsListViewProtocol?
    private var domains: [DomainDisplayInfo] = []
    private var selectedDomain: DomainDisplayInfo?
    private let fetchLimit: Int = 10
    
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
            openChat(configuration.chat)
        }
    }
}

// MARK: - Private functions
private extension ChatsListViewPresenter {
    func showData() {
        Task {
            do {
                await loadDomains()
                var snapshot = ChatsListSnapshot()
                
                
                guard let selectedDomain else { return }
                
                snapshot.appendSections([.domainsSelection])
                
                let chatsList = try await appContext.messagingService.getChatsListForDomain(selectedDomain,
                                                                                           page: 1,
                                                                                           limit: fetchLimit)
                snapshot.appendSections([.channels])
                snapshot.appendItems(chatsList.map({ ChatsListViewController.Item.channel(configuration: .init(chat: $0)) }))
                
                view?.applySnapshot(snapshot, animated: true)
            } catch {
                Debugger.printFailure(error.localizedDescription) // TODO: - Handle error
            }
        }
    }
    
    func loadDomains() async {
        if domains.isEmpty {
            domains = await appContext.dataAggregatorService.getDomainsDisplayInfo().filter({ $0.isSetForRR })
            selectedDomain = domains.first
        }
    }
    
    func openChat(_ chat: MessagingChatDisplayInfo) {
        guard let nav = view?.cNavigationController,
            let selectedDomain else { return }
        
        UDRouter().showChatScreen(chat: chat, domain: selectedDomain, in: nav)
    }
}
