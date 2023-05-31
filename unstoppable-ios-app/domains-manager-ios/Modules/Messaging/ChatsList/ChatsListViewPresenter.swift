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
            openChannel(configuration.channelType)
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
                
                let channels = try await appContext.messagingService.getChannelsForDomain(selectedDomain, page: 0, limit: fetchLimit)
                snapshot.appendSections([.channels])
                snapshot.appendItems(channels.map({ ChatsListViewController.Item.channel(configuration: .init(channelType: $0)) }))
                
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
    
    func openChannel(_ channelType: ChatChannelType) {
        guard let nav = view?.cNavigationController,
            let selectedDomain else { return }
        
        UDRouter().showChatScreen(channelType: channelType, domain: selectedDomain, in: nav)
    }
}
