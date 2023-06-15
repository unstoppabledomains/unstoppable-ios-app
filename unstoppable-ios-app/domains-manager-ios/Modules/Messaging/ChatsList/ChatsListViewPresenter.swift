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
    func didSelectWallet(_ wallet: WalletDisplayInfo)
    func actionButtonPressed()
}

@MainActor
final class ChatsListViewPresenter {
    
    private weak var view: ChatsListViewProtocol?
    private let fetchLimit: Int = 10

    private var wallets: [WalletDisplayInfo] = []
    private var profileWalletPairsCache: [ChatProfileWalletPair] = []
    private var selectedProfileWalletPair: ChatProfileWalletPair?
    private var selectedDataType: ChatsListDataType = .chats
    private var didLoadTime = Date()
    
    private var chatsList: [MessagingChatDisplayInfo] = []
    private var channels: [MessagingNewsChannel] = []
    
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
            
            showData()
        case .chat(let configuration):
            openChat(configuration.chat)
        case .chatRequests:
            showChatRequests()
        case .channel(let configuration):
            openChannel(configuration.channel)
        case .dataTypeSelection, .createProfile, .emptyState:
            return
        }
    }
    
    func didSelectWallet(_ wallet: WalletDisplayInfo) {
        guard wallet.address != selectedProfileWalletPair?.wallet.address else { return }
        
        runLoadingState()
        Task {
            if let cachedPair = profileWalletPairsCache.first(where: { $0.wallet.address == wallet.address }) {
                try await self.selectProfileWalletPair(cachedPair)
            } else {
                var profile: MessagingChatUserProfileDisplayInfo?
                if let rrDomain = wallet.reverseResolutionDomain {
                   profile = try? await appContext.messagingService.getUserProfile(for: rrDomain)
                }
                
                try await selectProfileWalletPair(.init(wallet: wallet,
                                              profile: profile))
            }
        }
    }
    
    func actionButtonPressed() {
        Task {
            guard let selectedProfileWalletPair,
                  let view else { return }
            
            do {
                try await appContext.authentificationService.verifyWith(uiHandler: view,
                                                                        purpose: .confirm)
                let wallet = selectedProfileWalletPair.wallet
                if let rrDomain = wallet.reverseResolutionDomain {
                    createProfileFor(domain: rrDomain,
                                     in: wallet)
                } else {
                    askToSetRRDomainAndCreateProfileFor(wallet: selectedProfileWalletPair.wallet)
                }
            } catch { }
        }
    }
}

// MARK: - MessagingServiceListener
extension ChatsListViewPresenter: MessagingServiceListener {
   nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
       Task { @MainActor in
           switch messagingDataType {
           case .chats(let chats, let wallet):
               if wallet == selectedProfileWalletPair?.wallet.address,
                  chatsList != chats {
                   chatsList = chats
                   showData()
               }
           case .channels(let channels, let wallet):
               if wallet == selectedProfileWalletPair?.wallet.address {
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
    func runLoadingState() {
        chatsList.removeAll()
        channels.removeAll()
        view?.setState(.loading)
    }
    
    func loadAndShowData() {
        Task {
            didLoadTime = Date()
            do {
                wallets = await appContext.dataAggregatorService.getWalletsWithInfo()
                    .compactMap { $0.displayInfo }
                    .filter { $0.domainsCount > 0 }
                    .sorted(by: {
                    if $0.reverseResolutionDomain == nil && $1.reverseResolutionDomain != nil {
                        return false
                    } else if $0.reverseResolutionDomain != nil && $1.reverseResolutionDomain == nil {
                        return true
                    }
                    return $0.domainsCount > $1.domainsCount
                })
                
                guard !wallets.isEmpty else {
                    Debugger.printWarning("User got to chats screen without wallets with domains")
                    await awaitForUIReady()
                    view?.cNavigationController?.popViewController(animated: true)
                    return
                }
                
                if let lastUsedWallet = UserDefaults.currentMessagingOwnerWallet,
                   let wallet = wallets.first(where: { $0.address == lastUsedWallet }),
                   let rrDomain = wallet.reverseResolutionDomain,
                   let profile = try? await appContext.messagingService.getUserProfile(for: rrDomain) {
                    /// User already used chat with some profile, select last used.
                    try await selectProfileWalletPair(.init(wallet: wallet,
                                                  profile: profile))
                } else {
                    for wallet in wallets {
                        guard let rrDomain = wallet.reverseResolutionDomain else { continue }
                        
                        if let profile = try? await appContext.messagingService.getUserProfile(for: rrDomain) {
                            /// User open chats for the first time but there's existing profile, use it as default
                            try await selectProfileWalletPair(.init(wallet: wallet,
                                                          profile: profile))
                            return
                        } else {
                            profileWalletPairsCache.append(.init(wallet: wallet,
                                                                 profile: nil))
                        }
                    }
              
                    /// No profile has found for existing RR domains
                    /// Select first wallet from sorted list
                    let firstWallet = wallets[0] /// Safe due to .isEmpty verification above
                    try await selectProfileWalletPair(.init(wallet: firstWallet,
                                                  profile: nil))
                }
            } catch {
                view?.showAlertWith(error: error, handler: nil) // TODO: - Handle error
            }
        }
    }
    
    func awaitForUIReady() async {
        let timeSinceViewDidLoad = Date().timeIntervalSince(didLoadTime)
        let uiReadyTime = CNavigationController.animationDuration
        
        let dif = uiReadyTime - timeSinceViewDidLoad
        if dif > 0 {
            try? await Task.sleep(seconds: dif)
        }
    }
    
    func selectProfileWalletPair(_ chatProfile: ChatProfileWalletPair) async throws {
        self.selectedProfileWalletPair = chatProfile
        
        if let i = profileWalletPairsCache.firstIndex(where: { $0.wallet.address == chatProfile.wallet.address }) {
            profileWalletPairsCache[i] = chatProfile // Update cache
        } else {
            profileWalletPairsCache.append(chatProfile)
        }
        
        view?.setNavigationWith(selectedWallet: chatProfile.wallet,
                                wallets: wallets)
        
        guard let profile = chatProfile.profile else {
            await awaitForUIReady()
            view?.setState(.createProfile)
            showData()
            return
        }
        
        UserDefaults.currentMessagingOwnerWallet = profile.wallet.normalized
        
        async let chatsListTask = appContext.messagingService.getChatsListForProfile(profile)
        async let channelsTask = appContext.messagingService.getSubscribedChannelsForProfile(profile)
        
        let (chatsList, channels) = try await (chatsListTask, channelsTask)
        
        self.chatsList = chatsList
        self.channels = channels
        
        await awaitForUIReady()
        view?.setState(.chatsList)
        showData()
        appContext.messagingService.setCurrentUser(profile)
    }
    
    func showData() {
        var snapshot = ChatsListSnapshot()
        
        if selectedProfileWalletPair?.profile == nil {
            snapshot.appendSections([.createProfile])
            snapshot.appendItems([.createProfile])
        } else {
            let dataTypeSelectionUIConfiguration = getDataTypeSelectionUIConfiguration()
            snapshot.appendSections([.dataTypeSelection])
            snapshot.appendItems([.dataTypeSelection(configuration: dataTypeSelectionUIConfiguration)])
            
            switch selectedDataType {
            case .chats:
                if chatsList.isEmpty {
                    snapshot.appendSections([.emptyState])
                    snapshot.appendItems([.emptyState(configuration: .init(dataType: selectedDataType))])
                } else {
                    snapshot.appendSections([.channels])
                    let requestsList = chatsList.filter({ !$0.isApproved })
                    let approvedList = chatsList.filter({ $0.isApproved })
                    if !requestsList.isEmpty {
                        snapshot.appendItems([.chatRequests(configuration: .init(dataType: selectedDataType,
                                                                                 numberOfRequests: requestsList.count))])
                    }
                    snapshot.appendItems(approvedList.map({ ChatsListViewController.Item.chat(configuration: .init(chat: $0)) }))
                }
            case .inbox:
                if channels.isEmpty {
                    snapshot.appendSections([.emptyState])
                    snapshot.appendItems([.emptyState(configuration: .init(dataType: selectedDataType))])
                } else {
                    snapshot.appendSections([.channels])
                    let spamList = channels.filter({ $0.blocked == 1 })
                    if !spamList.isEmpty {
                        snapshot.appendItems([.chatRequests(configuration: .init(dataType: selectedDataType,
                                                                                 numberOfRequests: spamList.count))])
                    }
                    snapshot.appendItems(channels.map({ ChatsListViewController.Item.channel(configuration: .init(channel: $0)) }))
                }
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
    
    func openChat(_ chat: MessagingChatDisplayInfo) {
        guard let nav = view?.cNavigationController,
              let rrDomain = selectedProfileWalletPair?.wallet.reverseResolutionDomain else { return }
        
        UDRouter().showChatScreen(chat: chat, domain: rrDomain, in: nav)
    }
    
    func showChatRequests() {
        
    }
    
    func openChannel(_ channel: MessagingNewsChannel) {
        
    }
    
    func askToSetRRDomainAndCreateProfileFor(wallet: WalletDisplayInfo) {
        Task {
            guard let view,
                let udWallet = appContext.udWalletsService.getUserWallets().first(where: { $0.address == wallet.address }) else { return }
            
            let result = await UDRouter().runSetupReverseResolutionFlow(in: view,
                                                                        for: udWallet,
                                                                        walletInfo: wallet,
                                                                        mode: .chooseFirstForMessaging)
            
            switch result {
            case .cancelled:
                return
            case .set(let domain):
                var wallet = wallet
                wallet.reverseResolutionDomain = domain
                createProfileFor(domain: domain, in: wallet)
            }
        }
    }
    
    func createProfileFor(domain: DomainDisplayInfo,
                          in wallet: WalletDisplayInfo) {
        Task {
            do {
                let profile = try await appContext.messagingService.createUserProfile(for: domain)
                try await selectProfileWalletPair(.init(wallet: wallet,
                                                        profile: profile))
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
        }
    }
}

// MARK: - Private methods
private extension ChatsListViewPresenter {
    struct ChatProfileWalletPair {
        let wallet: WalletDisplayInfo
        let profile: MessagingChatUserProfileDisplayInfo?
    }
}
