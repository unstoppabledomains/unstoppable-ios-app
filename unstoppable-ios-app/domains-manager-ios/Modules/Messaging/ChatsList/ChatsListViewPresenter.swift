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
    private var requestsList: [MessagingChatDisplayInfo] = []
    private var selectedDataType: ChatsListDataType = .chats
    
    init(view: ChatsListViewProtocol) {
        self.view = view
    }
}

// MARK: - ChatsListViewPresenterProtocol
extension ChatsListViewPresenter: ChatsListViewPresenterProtocol {
    func viewDidLoad() {
        appContext.messagingService.addListener(self)
        loadAndShowData()
    }
    
    func didSelectItem(_ item: ChatsListViewController.Item) {
        UDVibration.buttonTap.vibrate()
        switch item {
        case .domainSelection(let configuration):
            guard !configuration.isSelected else { return }
            
            selectedDomain = configuration.domain
            showData()
        case .chat(let configuration):
            openChat(configuration.chat)
        case .chatRequests:
            showChatRequests()
        case .dataTypeSelection:
            return
        }
    }
}

// MARK: - MessagingServiceListener
extension ChatsListViewPresenter: MessagingServiceListener {
   nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
       Task { @MainActor in
           switch messagingDataType {
           case .chats(let chats, let isRequests, let wallet):
               if wallet == selectedDomain?.ownerWallet {
                   if isRequests {
                       requestsList = chats
                   } else {
                       chatsList = chats
                   }
                   showData()
               }
           case .messages:
               return
           }
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

                async let chatsListTask = appContext.messagingService.getChatsListForDomain(selectedDomain,
                                                                                            page: 1,
                                                                                            limit: fetchLimit)
                async let requestsListTask = appContext.messagingService.getChatRequestsForDomain(selectedDomain,
                                                                                               page: 1,
                                                                                               limit: fetchLimit)
                async let channelsTask = appContext.messagingService.getSubscribedChannelsFor(domain: selectedDomain)
                
                let (chatsList, requestsList, channels) = try await (chatsListTask, requestsListTask, channelsTask)
                
                self.chatsList = chatsList
                self.requestsList = requestsList
                
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
            if !requestsList.isEmpty {
                snapshot.appendItems([.chatRequests(configuration: .init(numberOfRequests: requestsList.count))])
            }
            snapshot.appendItems(chatsList.map({ ChatsListViewController.Item.chat(configuration: .init(chat: $0)) }))
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
            let allDomains = await appContext.dataAggregatorService.getDomainsDisplayInfo()
            domains = allDomains.filter({ $0.isSetForRR })
            selectedDomain = domains.last ?? allDomains.first
        }
    }
    
    func openChat(_ chat: MessagingChatDisplayInfo) {
        guard let nav = view?.cNavigationController,
            let selectedDomain else { return }
        
        UDRouter().showChatScreen(chat: chat, domain: selectedDomain, in: nav)
    }
    
    func showChatRequests() {
        
    }
}
