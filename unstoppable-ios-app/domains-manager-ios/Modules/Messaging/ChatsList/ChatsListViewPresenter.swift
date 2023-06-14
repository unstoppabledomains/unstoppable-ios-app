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
    private var selectedProfile: MessagingChatUserProfileDisplayInfo?
    private let fetchLimit: Int = 10
    private var chatsList: [MessagingChatDisplayInfo] = []
    private var channels: [MessagingNewsChannel] = []
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
        case .channel(let configuration):
            openChannel(configuration.channel)
        case .dataTypeSelection, .createProfile:
            return
        }
    }
}

// MARK: - MessagingServiceListener
extension ChatsListViewPresenter: MessagingServiceListener {
   nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
       Task { @MainActor in
           switch messagingDataType {
           case .chats(let chats, let wallet):
               if wallet == selectedDomain?.ownerWallet,
                  chatsList != chats {
                   chatsList = chats
                   showData()
               }
           case .channels(let channels, let wallet):
               if wallet == selectedDomain?.ownerWallet {
                   self.channels = channels
                   showData()
               }
           case .messageUpdated, .messagesRemoved, .messagesAdded:
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
                
                guard let selectedProfile else {
                    
                    showData()
                    return }
                
                async let chatsListTask = appContext.messagingService.getChatsListForProfile(selectedProfile)
                async let channelsTask = appContext.messagingService.getSubscribedChannelsForProfile(selectedProfile)

                let (chatsList, channels) = try await (chatsListTask, channelsTask)

                self.chatsList = chatsList
                self.channels = channels
                
                UserDefaults.currentMessagingOwnerWallet = selectedProfile.wallet.normalized

                showData()
                
                appContext.messagingService.setCurrentUser(selectedProfile)
            } catch {
                view?.showAlertWith(error: error, handler: nil) // TODO: - Handle error
            }
        }
    }
    
    func showData() {
        var snapshot = ChatsListSnapshot()
        
        if selectedProfile == nil {
            snapshot.appendSections([.createProfile])
            snapshot.appendItems([.createProfile])
        } else {
            let dataTypeSelectionUIConfiguration = getDataTypeSelectionUIConfiguration()
            snapshot.appendSections([.dataTypeSelection])
            snapshot.appendItems([.dataTypeSelection(configuration: dataTypeSelectionUIConfiguration)])
            
            switch selectedDataType {
            case .chats:
                snapshot.appendSections([.channels])
                let requestsList = chatsList.filter({ !$0.isApproved })
                let approvedList = chatsList.filter({ $0.isApproved })
                if !requestsList.isEmpty {
                    snapshot.appendItems([.chatRequests(configuration: .init(dataType: selectedDataType,
                                                                             numberOfRequests: requestsList.count))])
                }
                snapshot.appendItems(approvedList.map({ ChatsListViewController.Item.chat(configuration: .init(chat: $0)) }))
            case .inbox:
                snapshot.appendSections([.channels])
                let spamList = channels.filter({ $0.blocked == 1 })
                if !spamList.isEmpty {
                    snapshot.appendItems([.chatRequests(configuration: .init(dataType: selectedDataType,
                                                                             numberOfRequests: spamList.count))])
                }
                snapshot.appendItems(channels.map({ ChatsListViewController.Item.channel(configuration: .init(channel: $0)) }))
            }
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
    
    func openChannel(_ channel: MessagingNewsChannel) {
        
    }
}
