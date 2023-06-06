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
    private var chatsList: [MessagingChatDisplayInfo] = []
    private var selectedDataType: ChatsListDataType = .chats
    
    init(view: ChatsListViewProtocol) {
        self.view = view
    }
}

// MARK: - ChatsListViewPresenterProtocol
extension ChatsListViewPresenter: ChatsListViewPresenterProtocol {
    func viewDidLoad() {
        loadAndShowData()
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
        case .dataTypeSelection:
            return
        }
    }
}

// MARK: - Private functions
private extension ChatsListViewPresenter {
    func loadAndShowData() {
        Task {
            do {
                await loadDomains()
                guard let selectedDomain else { return }

                chatsList = try await appContext.messagingService.getChatsListForDomain(selectedDomain,
                                                                                        page: 1,
                                                                                        limit: fetchLimit)
                showData()
            } catch {
                view?.showAlertWith(error: error, handler: nil) // TODO: - Handle error
            }
        }
    }
    
    func showData() {
        var snapshot = ChatsListSnapshot()
        
        let dataTypeSelectionUIConfiguration = getDataTypeSelectionUIConfiguration()
        snapshot.appendSections([.dataTypeSelection])
        snapshot.appendItems([.dataTypeSelection(configuration: dataTypeSelectionUIConfiguration)])
        
        switch selectedDataType {
        case .chats:
            snapshot.appendSections([.channels])
            snapshot.appendItems(chatsList.map({ ChatsListViewController.Item.channel(configuration: .init(chat: $0)) }))
        case .inbox:
            Void()
        }
        
        view?.applySnapshot(snapshot, animated: true)
    }
    
    func getDataTypeSelectionUIConfiguration() -> ChatsListViewController.DataTypeSelectionUIConfiguration {
        let chatsBadge = 0
        let inboxBadge = 0
        
        return .init(dataTypesConfigurations: [.init(dataType: .chats, badge: chatsBadge),
                                               .init(dataType: .inbox, badge: inboxBadge)],
                     selectedDataType: selectedDataType) { [weak self] newSelectedDataType in
            self?.selectedDataType = newSelectedDataType
            self?.showData()
        }
    }
    
    func loadDomains() async {
        if domains.isEmpty {
            domains = await appContext.dataAggregatorService.getDomainsDisplayInfo().filter({ $0.isSetForRR })
            selectedDomain = domains.last
        }
    }
    
    func openChat(_ chat: MessagingChatDisplayInfo) {
        guard let nav = view?.cNavigationController,
            let selectedDomain else { return }
        
        UDRouter().showChatScreen(chat: chat, domain: selectedDomain, in: nav)
    }
}
