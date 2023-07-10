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
    
    func didStartSearch()
    func didStopSearch()
    func didSearchWith(key: String)
}

extension ChatsListViewPresenterProtocol {
    func didSelectWallet(_ wallet: WalletDisplayInfo) { }
    func actionButtonPressed() { }
    func didStartSearch() { }
    func didStopSearch() { }
    func didSearchWith(key: String) { }
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
    private var searchData = SearchData()
    private let searchManager = SearchManager(debounce: 0.3)
    
    
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
        view?.hideKeyboard()
        switch item {
        case .domainSelection(let configuration):
            guard !configuration.isSelected else { return }
            
            showData()
        case .chat(let configuration):
            openChatWith(conversationState: .existingChat(configuration.chat))
        case .chatRequests:
            showChatRequests()
        case .channel(let configuration):
            openChannel(configuration.channel)
        case .userInfo(let configuration):
            openChatWith(conversationState: .newChat(configuration.userInfo))
        case .dataTypeSelection, .createProfile, .emptyState, .emptySearch:
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
    
    func didSearchWith(key: String) {
        self.searchData.searchKey = key.trimmedSpaces
        guard let profile = selectedProfileWalletPair?.profile else { return }
        Task {
            do {
                let (searchUsers, searchChannels) = try await searchManager.search(with: key,
                                                                                   page: 1,
                                                                                   limit: fetchLimit,
                                                                                   for: profile)
                searchData.searchUsers = searchUsers
                searchData.searchChannels = searchChannels
                showData()
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
        }
    }
    
    func didStartSearch() {
        self.searchData.isSearchActive = true
        showData()
    }
    
    func didStopSearch() {
        self.searchData = SearchData()
        didSearchWith(key: "")
        showData()
    }
}

// MARK: - MessagingServiceListener
extension ChatsListViewPresenter: MessagingServiceListener {
   nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
       Task { @MainActor in
           switch messagingDataType {
           case .chats(let chats, let profile):
               if profile.id == selectedProfileWalletPair?.profile?.id,
                  chatsList != chats {
                   chatsList = chats
                   showData()
               }
           case .channels(let channels, let profile):
               if profile.id == selectedProfileWalletPair?.profile?.id {
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
        let uiReadyTime = CNavigationController.animationDuration + 0.3
        
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
            fillSnapshotForUserWithoutProfile(&snapshot)
        } else {
            if searchData.isSearchActive {
                fillSnapshotForSearchActiveState(&snapshot)
            } else {
                let dataTypeSelectionUIConfiguration = getDataTypeSelectionUIConfiguration()
                snapshot.appendSections([.dataTypeSelection])
                snapshot.appendItems([.dataTypeSelection(configuration: dataTypeSelectionUIConfiguration)])
                
                switch selectedDataType {
                case .chats:
                    fillSnapshotForUserChatsList(&snapshot)
                case .channels:
                    fillSnapshotForUserChannelsList(&snapshot)
                }
            }
        }
        
        view?.applySnapshot(snapshot, animated: true)
    }
    
    func fillSnapshotForUserWithoutProfile(_ snapshot: inout ChatsListSnapshot) {
        snapshot.appendSections([.createProfile])
        snapshot.appendItems([.createProfile])
    }
    
    func fillSnapshotForUserChatsList(_ snapshot: inout ChatsListSnapshot) {
        if chatsList.isEmpty {
            snapshot.appendSections([.emptyState])
            snapshot.appendItems([.emptyState(configuration: .init(dataType: selectedDataType))])
        } else {
            snapshot.appendSections([.listItems(title: nil)])
            let requestsList = chatsList.requestsOnly()
            let approvedList = chatsList.confirmedOnly()
            if !requestsList.isEmpty {
                snapshot.appendItems([.chatRequests(configuration: .init(dataType: selectedDataType,
                                                                         numberOfRequests: requestsList.count))])
            }
            snapshot.appendItems(approvedList.map({ ChatsListViewController.Item.chat(configuration: .init(chat: $0)) }))
        }
    }
    
    func fillSnapshotForUserChannelsList(_ snapshot: inout ChatsListSnapshot) {
        if channels.isEmpty {
            snapshot.appendSections([.emptyState])
            snapshot.appendItems([.emptyState(configuration: .init(dataType: selectedDataType))])
        } else {
            snapshot.appendSections([.listItems(title: nil)])
            let channelsList = channels.filter({ $0.isCurrentUserSubscribed })
            let spamList = channels.filter({ !$0.isCurrentUserSubscribed })
            if !spamList.isEmpty {
                snapshot.appendItems([.chatRequests(configuration: .init(dataType: selectedDataType,
                                                                         numberOfRequests: spamList.count))])
            }
            snapshot.appendItems(channelsList.map({ ChatsListViewController.Item.channel(configuration: .init(channel: $0)) }))
        }
    }
    
    func fillSnapshotForSearchActiveState(_ snapshot: inout ChatsListSnapshot) {
        enum PeopleSearchResult {
            case existingChat(MessagingChatDisplayInfo)
            case newUser(MessagingChatUserDisplayInfo)
            
            var item: ChatsListViewController.Item {
                switch self {
                case .existingChat(let chat):
                    return .chat(configuration: .init(chat: chat))
                case .newUser(let userInfo):
                    return .userInfo(configuration: .init(userInfo: userInfo))
                }
            }
        }
        
        var people = [PeopleSearchResult]()
        var channels = [MessagingNewsChannel]()
        if searchData.searchKey.isEmpty {
            people = chatsList.map({ .existingChat($0) })
            channels = self.channels
        } else {
            people = searchData.searchUsers.map({ .newUser($0) })
            let subscribedChannelsIds = self.channels.map { $0.id }
            channels = searchData.searchChannels.filter({ !subscribedChannelsIds.contains($0.id) })
        }
        
        if people.isEmpty && channels.isEmpty {
            snapshot.appendSections([.emptyState])
            snapshot.appendItems([.emptySearch])
        } else {
            if !people.isEmpty {
                snapshot.appendSections([.listItems(title: "People")])
                snapshot.appendItems(people.map({ $0.item }))
            }
            if !channels.isEmpty {
                snapshot.appendSections([.listItems(title: "Apps")])
                snapshot.appendItems(channels.map({ ChatsListViewController.Item.channel(configuration: .init(channel: $0)) }))
            }
        }
    }
    
    func getDataTypeSelectionUIConfiguration() -> ChatsListViewController.DataTypeSelectionUIConfiguration {
        let chatsBadge = 0
        let inboxBadge = 0
        
        return .init(dataTypesConfigurations: [.init(dataType: .chats, badge: chatsBadge),
                                               .init(dataType: .channels, badge: inboxBadge)],
                     selectedDataType: selectedDataType) { [weak self] newSelectedDataType in
            self?.selectedDataType = newSelectedDataType
            self?.showData()
        }
    }
    
    func openChatWith(conversationState: MessagingChatConversationState) {
        guard let profile = selectedProfileWalletPair?.profile,
              let nav = view?.cNavigationController else { return }
        
        UDRouter().showChatScreen(profile: profile,
                                  conversationState: conversationState,
                                  in: nav)
    }
    
    func showChatRequests() {
        guard let profile = selectedProfileWalletPair?.profile,
              let nav = view?.cNavigationController else { return }
        
        switch selectedDataType {
        case .chats:
            let requests = chatsList.requestsOnly()
            guard !requests.isEmpty else { return }
            
            UDRouter().showChatRequestsScreen(dataType: .chatRequests(requests),
                                              profile: profile,
                                              in: nav)
        case .channels:
            let channels = self.channels.filter { !$0.isCurrentUserSubscribed }
            guard !channels.isEmpty else { return }

            UDRouter().showChatRequestsScreen(dataType: .channelsRequests(channels),
                                              profile: profile,
                                              in: nav)
        }
    }
    
    func openChannel(_ channel: MessagingNewsChannel) {
        guard let profile = selectedProfileWalletPair?.profile,
              let nav = view?.cNavigationController else { return }
        
        UDRouter().showChannelScreen(profile: profile,
                                     channel: channel,
                                     in: nav)
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
    
    struct SearchData {
        var isSearchActive = false
        var searchKey: String = ""
        var searchUsers: [MessagingChatUserDisplayInfo] = []
        var searchChannels: [MessagingNewsChannel] = []
    }
}

private final class SearchManager {
    
    typealias SearchResult = ([MessagingChatUserDisplayInfo], [MessagingNewsChannel])
    typealias SearchUsersTask = Task<SearchResult, Error>
    
    private let debounce: TimeInterval
    private var currentTask: SearchUsersTask?
    
    init(debounce: TimeInterval) {
        self.debounce = debounce
    }
    
    func search(with searchKey: String,
                page: Int,
                limit: Int,
                for profile: MessagingChatUserProfileDisplayInfo) async throws -> SearchResult {
        // Cancel previous search task if it exists
        currentTask?.cancel()
        
        let debounce = self.debounce
        let task: SearchUsersTask = Task.detached {
            do {
                try await Task.sleep(seconds: debounce)
                try Task.checkCancellation()
                
                async let searchUsersTasks = appContext.messagingService.searchForUsersWith(searchKey: searchKey)
                async let searchChannelsTasks = appContext.messagingService.searchForChannelsWith(page: page, limit: limit,
                                                                                                  searchKey: searchKey, for: profile)
                
                let (users, channels) = try await (searchUsersTasks, searchChannelsTasks)
                
                try Task.checkCancellation()
                return (users, channels)
            } catch NetworkLayerError.requestCancelled, is CancellationError {
                return ([], [])
            } catch {
                throw error
            }
        }
        
        currentTask = task
        let users = try await task.value
        return users
    }
}
