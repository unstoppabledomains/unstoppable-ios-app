//
//  ChatsListViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

@MainActor
protocol ChatsListViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    var analyticsName: Analytics.ViewName { get }
    
    func didSelectItem(_ item: ChatsListViewController.Item)
    func didSelectWallet(_ wallet: WalletDisplayInfo)
    func actionButtonPressed()
    
    func createCommunitiesProfileButtonPressed()
    func didStartSearch(with mode: ChatsList.SearchMode)
    func didStopSearch()
    func didSearchWith(key: String)
}

extension ChatsListViewPresenterProtocol {
    func didSelectWallet(_ wallet: WalletDisplayInfo) { }
    func actionButtonPressed() { }
    func createCommunitiesProfileButtonPressed() { }
    func didStartSearch(with mode: ChatsList.SearchMode) { }
    func didStopSearch() { }
    func didSearchWith(key: String) { }
}

@MainActor
protocol ChatsListCoordinator {
    func update(presentOptions: ChatsList.PresentOptions)
}

@MainActor
final class ChatsListViewPresenter {
    
    private weak var view: ChatsListViewProtocol?
    private let fetchLimit: Int = 10
    private let messagingService: MessagingServiceProtocol
    private var presentOptions: ChatsList.PresentOptions

    private var wallets: [WalletDisplayInfo] = []
    private var profileWalletPairsCache: [ChatProfileWalletPair] = []
    private var selectedProfileWalletPair: ChatProfileWalletPair?
    private var selectedDataType: ChatsListDataType = .chats
    private var didLoadTime = Date()
    
    private var chatsList: [MessagingChatDisplayInfo] = []
    private var communitiesList: [MessagingChatDisplayInfo] = []
    private var channels: [MessagingNewsChannel] = []
    private var searchData = SearchData()
    private let searchManager = ChatsList.SearchManager(debounce: 0.3)
    
    var analyticsName: Analytics.ViewName { .chatsHome }
    
    init(view: ChatsListViewProtocol,
         presentOptions: ChatsList.PresentOptions,
         messagingService: MessagingServiceProtocol) {
        self.view = view
        self.presentOptions = presentOptions
        self.messagingService = messagingService
        appContext.udWalletsService.addListener(self)
    }
}

// MARK: - ChatsListViewPresenterProtocol
extension ChatsListViewPresenter: ChatsListViewPresenterProtocol {
    func viewDidLoad() {
        messagingService.addListener(self)
        loadAndShowData()
    }
    
    func didSelectItem(_ item: ChatsListViewController.Item) {
        UDVibration.buttonTap.vibrate()
        view?.stopSearching()
        switch item {
        case .domainSelection(let configuration):
            guard !configuration.isSelected else { return }
            
            showData()
        case .chat(let configuration):
            switch configuration.chat.type {
            case .private:
                logButtonPressedAnalyticEvents(button: .chatInList)
            case .group:
                logButtonPressedAnalyticEvents(button: .groupChatInList)
            case .community:
                logButtonPressedAnalyticEvents(button: .chatInList) // TODO: - Communities
            }
            openChatWith(conversationState: .existingChat(configuration.chat))
        case .chatRequests(let configuration):
            switch configuration.dataType {
            case .chats:
                logButtonPressedAnalyticEvents(button: .chatRequests)
            case .communities:
                logButtonPressedAnalyticEvents(button: .chatRequests) // TODO: - Communities
            case .channels:
                logButtonPressedAnalyticEvents(button: .channelsSpam)
            }
            showCurrentDataTypeRequests()
        case .channel(let configuration):
            logButtonPressedAnalyticEvents(button: .channelInList)
            openChannel(configuration.channel)
        case .userInfo(let configuration):
            logButtonPressedAnalyticEvents(button: .userToChatInList)
            if let existingChat = chatsList.first(where: { $0.type.otherUserDisplayInfo?.wallet.normalized == configuration.userInfo.wallet.normalized }) {
                openChatWith(conversationState: .existingChat(existingChat))
            } else {
                // TODO: - Move service determinition into MessagingService
                openChatWith(conversationState: .newChat(.init(userInfo: configuration.userInfo, messagingService: .xmtp)))
            }
        case .dataTypeSelection, .createProfile, .emptyState, .emptySearch:
            return
        }
    }
    
    func didSelectWallet(_ wallet: WalletDisplayInfo) {
        guard wallet.address != selectedProfileWalletPair?.wallet.address else { return }
        
        logButtonPressedAnalyticEvents(button: .messagingProfileInList, parameters: [.wallet: wallet.address])
        runLoadingState()
        Task {
            if let cachedPair = profileWalletPairsCache.first(where: { $0.wallet.address == wallet.address }) {
                try await self.selectProfileWalletPair(cachedPair)
            } else {
                var profile: MessagingChatUserProfileDisplayInfo?
                var isUDBlueEnabled = false
                if let rrDomain = wallet.reverseResolutionDomain {
                    profile = try? await messagingService.getUserMessagingProfile(for: rrDomain)
                    isUDBlueEnabled = await getUDBlueEnabledStatus(for: rrDomain)
                }
                let isCommunitiesEnabled = await isCommunitiesEnabled(for: profile)
                try await selectProfileWalletPair(.init(wallet: wallet,
                                                        profile: profile,
                                                        isCommunitiesEnabled: isCommunitiesEnabled,
                                                        isUDBlueEnabled: isUDBlueEnabled))
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
    
    func createCommunitiesProfileButtonPressed() {
        Task {
            guard let selectedProfileWalletPair,
                  let profile = selectedProfileWalletPair.profile,
                  let view else { return }
            
            do {
                try await appContext.authentificationService.verifyWith(uiHandler: view,
                                                                        purpose: .confirm)
                try await messagingService.createCommunityProfile(for: profile)
                let isUDBlueEnabled = await getUDBlueEnabledStatus(for: selectedProfileWalletPair.wallet.reverseResolutionDomain)
                try await selectProfileWalletPair(.init(wallet: selectedProfileWalletPair.wallet,
                                                        profile: profile,
                                                        isCommunitiesEnabled: true,
                                                        isUDBlueEnabled: isUDBlueEnabled))
            } catch {
                view.showAlertWith(error: error, handler: nil)
            }
        }
    }
    
    func didSearchWith(key: String) {
        let key = key.trimmedSpaces
        self.searchData.searchKey = key.trimmedSpaces
        searchData.searchUsers = []
        searchData.searchChannels = []
        guard let profile = selectedProfileWalletPair?.profile else { return }
        Task {
            do {
                let (searchUsers, searchChannels, domainNames) = try await searchManager.search(with: key,
                                                                                                mode: searchData.mode,
                                                                                                page: 1,
                                                                                                limit: fetchLimit,
                                                                                                for: profile)
                searchData.searchUsers = searchUsers
                searchData.searchChannels = searchChannels
                searchData.domainProfiles = domainNames
                showData()
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
        }
    }
    
    func didStartSearch(with mode: ChatsList.SearchMode) {
        self.searchData.isSearchActive = true
        self.searchData.mode = mode
        showData()
    }
    
    func didStopSearch() {
        self.searchData = SearchData()
        didSearchWith(key: "")
        showData()
    }
}

// MARK: - ChatsListCoordinator
extension ChatsListViewPresenter: ChatsListCoordinator {
    func update(presentOptions: ChatsList.PresentOptions) {
        func prepareToAutoOpenWith(profile: MessagingChatUserProfileDisplayInfo,
                                   dataType: ChatsListDataType) async throws {
            await popToChatsList()
            if selectedDataType != dataType {
                selectedDataType = dataType
                showData()
            }
            try await preselectProfile(profile, usingWallets: wallets)
        }
        
        Task {
            do {
                let appCoordinator = appContext.coreAppCoordinator
                switch presentOptions {
                case .default:
                    self.presentOptions = presentOptions
                case .showChatsList(let profile):
                    if let profile {
                        try await prepareToAutoOpenWith(profile: profile, dataType: .chats)
                    } else {
                        self.presentOptions = presentOptions
                    }
                case .showChat(let options, let profile):
                    switch options {
                    case .existingChat(chatId: let chatId):
                        if selectedProfileWalletPair?.profile?.id != profile.id ||
                            !appCoordinator.isActiveState(.chatOpened(chatId: chatId)) {
                            try await prepareToAutoOpenWith(profile: profile, dataType: .chats)
                            tryAutoOpenChat(chatId, profile: profile)
                        }
                    case .newChat(let details):
                        try await prepareToAutoOpenWith(profile: profile, dataType: .chats)
                        autoOpenNewChat(with: details.userInfo, messagingService: details.messagingService)
                    }
                case .showChannel(let channelId, let profile):
                    if selectedProfileWalletPair?.profile?.id != profile.id ||
                        !appCoordinator.isActiveState(.channelOpened(channelId: channelId)) {
                        try await prepareToAutoOpenWith(profile: profile, dataType: .channels)
                        tryAutoOpenChannel(channelId, profile: profile)
                    }
                }
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
        }
    }
    
    private func popToChatsList() async {
        guard let view else { return }
        
        view.cNavigationController?.popToViewController(view, animated: true)
        try? await Task.sleep(seconds: CNavigationController.animationDuration)
    }
}

// MARK: - MessagingServiceListener
extension ChatsListViewPresenter: MessagingServiceListener {
   nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
       Task { @MainActor in
           switch messagingDataType {
           case .chats(let chats, let profile):
               if case .showChat(_, let showProfile) = presentOptions,
                  showProfile.id == profile.id {
                   loadAndShowData()
               } else if profile.id == selectedProfileWalletPair?.profile?.id,
                         chatsList != chats || Constants.shouldHideBlockedUsersLocally {
                   setNewChats(chats)
                   showData()
               }
           case .channels(let channels, let profile):
               if case .showChannel(_, let showProfile) = presentOptions,
                  showProfile.id == profile.id {
                   loadAndShowData()
               } else if profile.id == selectedProfileWalletPair?.profile?.id {
                   self.channels = channels
                   showData()
               }
           case .refreshOfUserProfile(let profile, _):
               if profile.id == selectedProfileWalletPair?.profile?.id {
                   updateNavigationUI()
               }
           case .messageReadStatusUpdated(let message, let numberOfUnreadMessagesInSameChat):
               if message.userId == selectedProfileWalletPair?.profile?.id,
                  let i = chatsList.firstIndex(where: { $0.id == message.chatId }) {
                   chatsList[i].unreadMessagesCount = numberOfUnreadMessagesInSameChat
                   if numberOfUnreadMessagesInSameChat == 0 {
                       showData()
                   }
               }
           case .messageUpdated, .messagesRemoved, .messagesAdded, .channelFeedAdded, .totalUnreadMessagesCountUpdated:
               return
           }
       }
    }
}

// MARK: - UDWalletsServiceListener
extension ChatsListViewPresenter: UDWalletsServiceListener {
    func walletsDataUpdated(notification: UDWalletsServiceNotification) {
        switch notification {
        case .walletsUpdated(let wallets):
            let addresses = wallets.map { $0.address }
            if let selectedAddress = selectedProfileWalletPair?.wallet.address,
               !addresses.contains(selectedAddress) {
                loadAndShowData()
            } else {
                refreshAvailableWalletsList()
            }
        case .reverseResolutionDomainChanged:
            refreshAvailableWalletsList()
        case .walletRemoved:
            return
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
                wallets = try await loadReadyForChattingWalletsOrClose()
                
                switch presentOptions {
                case .default:
                    try await resolveInitialProfileWith(wallets: wallets)
                case .showChatsList(let profile):
                    if let profile {
                        try await preselectProfile(profile, usingWallets: wallets)
                    } else {
                        try await resolveInitialProfileWith(wallets: wallets)
                    }
                case .showChat(let options, let profile):
                    try await preselectProfile(profile, usingWallets: wallets)
                    switch options {
                    case .existingChat(let chatId):
                        tryAutoOpenChat(chatId, profile: profile)
                    case .newChat(let details):
                        autoOpenNewChat(with: details.userInfo, messagingService: details.messagingService)
                    }
                case .showChannel(let channelId, let profile):
                    selectedDataType = .channels
                    try await preselectProfile(profile, usingWallets: wallets)
                    showData()
                    tryAutoOpenChannel(channelId, profile: profile)
                }
            } catch ChatsListError.noWalletsForChatting {
                return
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
        }
    }
    
    func setNewChats(_ chats: [MessagingChatDisplayInfo]) {
        (chatsList, communitiesList) = chats.splitCommunitiesAndOthers()
    }
    
    func refreshAvailableWalletsList() {
        Task {
            do {
                wallets = try await loadReadyForChattingWalletsOrClose()
                updateNavigationUI()
            } catch { }
        }
    }
    
    func loadReadyForChattingWalletsOrClose() async throws -> [WalletDisplayInfo] {
        let wallets = await messagingService.fetchWalletsAvailableForMessaging()
        guard !wallets.isEmpty else {
            Debugger.printWarning("User got to chats screen without wallets with domains")
            await awaitForUIReady()
            view?.cNavigationController?.popViewController(animated: true)
            throw ChatsListError.noWalletsForChatting
        }
        
        return wallets
    }
    
    func isCommunitiesEnabled(for messagingProfile: MessagingChatUserProfileDisplayInfo?) async -> Bool {
        if let messagingProfile {
            return await messagingService.isCommunitiesEnabled(for: messagingProfile)
        }
        return false
    }
    
    func resolveInitialProfileWith(wallets: [WalletDisplayInfo]) async throws {
        if let profile = await messagingService.getLastUsedMessagingProfile(among: wallets),
           let wallet = wallets.first(where: { $0.address == profile.wallet.normalized }) {
            /// User already used chat with some profile, select last used.
            let isCommunitiesEnabled = await isCommunitiesEnabled(for: profile)
            let isUDBlueEnabled = await getUDBlueEnabledStatus(for: wallet.reverseResolutionDomain)

            try await selectProfileWalletPair(.init(wallet: wallet,
                                                    profile: profile,
                                                    isCommunitiesEnabled: isCommunitiesEnabled,
                                                    isUDBlueEnabled: isUDBlueEnabled))
        } else {
            for wallet in wallets {
                guard let rrDomain = wallet.reverseResolutionDomain else { continue }
                let isUDBlueEnabled = await getUDBlueEnabledStatus(for: rrDomain)
                
                if let profile = try? await messagingService.getUserMessagingProfile(for: rrDomain) {
                    /// User open chats for the first time but there's existing profile, use it as default
                    let isCommunitiesEnabled = await isCommunitiesEnabled(for: profile)
                    try await selectProfileWalletPair(.init(wallet: wallet,
                                                            profile: profile,
                                                            isCommunitiesEnabled: isCommunitiesEnabled,
                                                            isUDBlueEnabled: isUDBlueEnabled))
                    return
                } else {
                    profileWalletPairsCache.append(.init(wallet: wallet,
                                                         profile: nil,
                                                         isCommunitiesEnabled: false,
                                                         isUDBlueEnabled: isUDBlueEnabled))
                }
            }
            
            /// No profile has found for existing RR domains
            /// Select first wallet from sorted list
            let firstWallet = wallets[0] /// Safe due to .isEmpty verification above
            try await selectProfileWalletPair(.init(wallet: firstWallet,
                                                    profile: nil,
                                                    isCommunitiesEnabled: false,
                                                    isUDBlueEnabled: false))
        }
    }
    
    func preselectProfile(_ profile: MessagingChatUserProfileDisplayInfo,
                          usingWallets wallets: [WalletDisplayInfo]) async throws {
        guard let wallet = wallets.first(where: { $0.address == profile.wallet.lowercased() }) else {
            try await resolveInitialProfileWith(wallets: wallets)
            return
        }
        let isCommunitiesEnabled = await isCommunitiesEnabled(for: profile)
        let isUDBlueEnabled = await getUDBlueEnabledStatus(for: wallet.reverseResolutionDomain)
        try await selectProfileWalletPair(.init(wallet: wallet,
                                                profile: profile,
                                                isCommunitiesEnabled: isCommunitiesEnabled,
                                                isUDBlueEnabled: isUDBlueEnabled))
    }
    
    func tryAutoOpenChat(_ chatId: String, profile: MessagingChatUserProfileDisplayInfo) {
        guard let chat = chatsList.first(where: { $0.id.contains(chatId) }) else { return }
        openChatWith(conversationState: .existingChat(chat))
        presentOptions = .default
    }
    
    func tryAutoOpenChannel(_ channelId: String, profile: MessagingChatUserProfileDisplayInfo) {
        guard let channel = channels.first(where: { $0.channel.normalized == channelId.normalized }) else { return }
        
        openChannel(channel)
        presentOptions = .default
    }
    
    func autoOpenNewChat(with userInfo: MessagingChatUserDisplayInfo, messagingService: MessagingServiceIdentifier) {
        openChatWith(conversationState: .newChat(.init(userInfo: userInfo, messagingService: messagingService)))
        self.presentOptions = .default
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
        
        guard let profile = chatProfile.profile else {
            let state: MessagingProfileStateAnalytics = chatProfile.wallet.reverseResolutionDomain == nil ? .notCreatedRRNotSet : .notCreatedRRSet
            logAnalytic(event: .willShowMessagingProfile,
                        parameters: [.state : state.rawValue,
                                     .wallet: chatProfile.wallet.address])
            await awaitForUIReady()
            updateNavigationUI()
            view?.setState(.createProfile)
            showData()
            return
        }
        
        logAnalytic(event: .willShowMessagingProfile, parameters: [.state : MessagingProfileStateAnalytics.created.rawValue,
                                                                   .wallet: profile.wallet])
        UserDefaults.currentMessagingOwnerWallet = profile.wallet.normalized
        
        async let chatsListTask = messagingService.getChatsListForProfile(profile)
        async let channelsTask = messagingService.getChannelsForProfile(profile)
        
        let (chats, channels) = try await (chatsListTask, channelsTask)
        
        setNewChats(chats)
        self.channels = channels
        
        await awaitForUIReady()
        updateNavigationUI()
        view?.setState(.chatsList)
        showData()
        messagingService.setCurrentUser(profile)
    }
    
    func updateNavigationUI() {
        guard let chatProfile = selectedProfileWalletPair else { return }
        
        var isLoading = false
        if let profile = chatProfile.profile {
            isLoading = messagingService.isUpdatingUserData(profile)
        }
        view?.setNavigationWith(selectedWallet: chatProfile.wallet,
                                wallets: wallets.map({ .init(wallet: $0, numberOfUnreadMessages: unreadMessagesCountFor(wallet: $0)) }),
                                isLoading: isLoading)
    }
    
    func unreadMessagesCountFor(wallet: WalletDisplayInfo) -> Int? {
        profileWalletPairsCache.first(where: { $0.wallet.address == wallet.address })?.profile?.unreadMessagesCount
    }
    
    func showData() {
        Task {
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
                    case .communities:
                        fillSnapshotForUserCommunitiesList(&snapshot)
                    case .channels:
                        fillSnapshotForUserChannelsList(&snapshot)
                    }
                }
            }
            
            view?.applySnapshot(snapshot, animated: true)
        }
    }
    
    func fillSnapshotForUserWithoutProfile(_ snapshot: inout ChatsListSnapshot) {
        snapshot.appendSections([.createProfile])
        snapshot.appendItems([.createProfile])
    }
    
    func getListOfUnblockedChats() -> [MessagingChatDisplayInfo] {
        chatsList.unblockedOnly()
    }
    
    func getListOfUnblockedCommunities() -> [MessagingChatDisplayInfo] {
        communitiesList.unblockedOnly()
    }
    
    func fillSnapshotForUserChatsList(_ snapshot: inout ChatsListSnapshot) {
        let chatsList = getListOfUnblockedChats()
        
        if chatsList.isEmpty {
            snapshot.appendSections([.emptyState])
            snapshot.appendItems([.emptyState(configuration: .emptyData(dataType: selectedDataType, isRequestsList: false))])
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
    
    // TODO: - Communities
    func fillSnapshotForUserCommunitiesList(_ snapshot: inout ChatsListSnapshot) {
        let communitiesList = getListOfUnblockedCommunities()
        
        if selectedProfileWalletPair?.isCommunitiesEnabled != true {
            snapshot.appendSections([.emptyState])
            snapshot.appendItems([.emptyState(configuration: .noCommunitiesProfile)])
        } else {
            if communitiesList.isEmpty {
                snapshot.appendSections([.emptyState])
                snapshot.appendItems([.emptyState(configuration: .emptyData(dataType: selectedDataType, isRequestsList: false))])
            } else {
                typealias GroupedCommunities = (joined: [MessagingChatDisplayInfo], notJoined: [MessagingChatDisplayInfo])
                
                let requestsList = communitiesList.requestsOnly()
                let approvedList = communitiesList.confirmedOnly()
                
                let groupedCommunities = approvedList.reduce(into: GroupedCommunities([], [])) { result, element in
                    switch element.type {
                    case .community(let details):
                        if details.isJoined {
                            result.joined.append(element)
                        } else {
                            result.notJoined.append(element)
                        }
                    default:
                        Void()
                    }
                }
                
                func addNotJoinedCommunitiesIfPossible(withTitle: Bool) {
                    guard !groupedCommunities.notJoined.isEmpty else { return }
                    
                    let title: String? = withTitle ? String.Constants.messagingCommunitiesSectionTitle.localized() : nil
                    snapshot.appendSections([.listItems(title: title)])
                    snapshot.appendItems(groupedCommunities.notJoined.map({ ChatsListViewController.Item.chat(configuration: .init(chat: $0)) }))
                }
                
                if !requestsList.isEmpty {
                    snapshot.appendSections([.listItems(title: nil)])
                    snapshot.appendItems([.chatRequests(configuration: .init(dataType: selectedDataType,
                                                                             numberOfRequests: requestsList.count))])
                    
                    snapshot.appendItems(groupedCommunities.joined.map({ ChatsListViewController.Item.chat(configuration: .init(chat: $0)) }))

                    addNotJoinedCommunitiesIfPossible(withTitle: true)
                } else if !groupedCommunities.joined.isEmpty {
                    snapshot.appendSections([.listItems(title: nil)])
                    snapshot.appendItems(groupedCommunities.joined.map({ ChatsListViewController.Item.chat(configuration: .init(chat: $0)) }))
                    
                    addNotJoinedCommunitiesIfPossible(withTitle: true)
                } else {
                    addNotJoinedCommunitiesIfPossible(withTitle: false)
                }
            }
        }
    }
    
    func fillSnapshotForUserChannelsList(_ snapshot: inout ChatsListSnapshot) {
        if channels.isEmpty {
            snapshot.appendSections([.emptyState])
            snapshot.appendItems([.emptyState(configuration: .emptyData(dataType: selectedDataType, isRequestsList: false))])
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
        let searchKey = searchData.searchKey.trimmedSpaces.lowercased()

        var people = [PeopleSearchResult]()
        var channels = [MessagingNewsChannel]()
        if searchKey.isEmpty {
            people = chatsList.map({ .existingChat($0) })
            channels = self.channels
        } else {
            /// Chats
            // Local chats
            let localChats = chatsList.filter { isChatMatchingSearchKey($0, searchKey: searchKey) }
            var localChatsPeopleWallets = Set(localChats.compactMap { $0.type.otherUserDisplayInfo?.wallet.lowercased() })
            localChatsPeopleWallets.insert(selectedProfileWalletPair?.wallet.address.lowercased() ?? "")
            people = localChats.map { .existingChat($0) }
            
            // Domain profiles
            let domainProfiles = searchData.domainProfiles.filter({ $0.ownerAddress != nil && $0.name != selectedProfileWalletPair?.wallet.reverseResolutionDomain?.name && !localChatsPeopleWallets.contains($0.ownerAddress!.lowercased()) })
            people += domainProfiles.map { profile in
                let pfpURL: URL? = profile.imageType == .default ? nil : URL(string: profile.imagePath ?? "")
                
                return .newUser(.init(wallet: profile.ownerAddress!, domainName: profile.name, pfpURL: pfpURL))
            }
            
            // Search users
            let remotePeople = searchData.searchUsers.filter({ searchUser in
                !localChatsPeopleWallets.contains(searchUser.wallet.lowercased()) &&
                !domainProfiles.contains(where: { $0.ownerAddress!.lowercased() == searchUser.wallet.lowercased()})
            })
            people += remotePeople.map { .newUser($0) }
            
            
            /// Channels
            let localChannels = self.channels.filter { $0.name.lowercased().contains(searchKey) }
            let subscribedChannelsIds = self.channels.map { $0.id }
            let remoteChannels = searchData.searchChannels.filter { !subscribedChannelsIds.contains($0.id) }
            channels = localChannels + remoteChannels
        }
        
        switch searchData.mode {
        case .default:
            Void()
        case .chatsOnly:
            channels.removeAll()
        case .channelsOnly:
            people.removeAll()
        }
        
        if people.isEmpty && channels.isEmpty {
            snapshot.appendSections([.emptyState])
            snapshot.appendItems([.emptySearch])
        } else {
            if !people.isEmpty {
                snapshot.appendSections([.listItems(title: String.Constants.people.localized())])
                snapshot.appendItems(people.map({ $0.item }))
            }
            if !channels.isEmpty {
                snapshot.appendSections([.listItems(title: String.Constants.apps.localized())])
                snapshot.appendItems(channels.map({ ChatsListViewController.Item.channel(configuration: .init(channel: $0)) }))
            }
        }
    }
    
    func isChatMatchingSearchKey(_ chat: MessagingChatDisplayInfo, searchKey: String) -> Bool {
        switch chat.type {
        case .private(let details):
            return isUserMatchSearchKey(details.otherUser, searchKey: searchKey)
        case .group(let details):
            let members = details.allMembers
            return members.first(where: { isUserMatchSearchKey($0, searchKey: searchKey) }) != nil
        case .community(let details):
            let members = details.members
            return members.first(where: { isUserMatchSearchKey($0, searchKey: searchKey) }) != nil
        }
    }
    
    func isUserMatchSearchKey(_ user: MessagingChatUserDisplayInfo, searchKey: String) -> Bool {
        if user.wallet.lowercased().contains(searchKey) {
            return true
        }
        return user.domainName?.lowercased().contains(searchKey) == true
    }
    
    func getDataTypeSelectionUIConfiguration() -> ChatsListViewController.DataTypeSelectionUIConfiguration {
        let chatsBadge = chatsList.reduce(0, { $0 + $1.unreadMessagesCount })
        let inboxBadge = channels.reduce(0, { $0 + $1.unreadMessagesCount })
        let communitiesBadge = chatsList.reduce(0, { $0 + $1.unreadMessagesCount })
        
        return .init(dataTypesConfigurations: [.init(dataType: .chats, badge: chatsBadge),
                                               .init(dataType: .communities, badge: communitiesBadge),
                                               .init(dataType: .channels, badge: inboxBadge)],
                     selectedDataType: selectedDataType) { [weak self] newSelectedDataType in
            self?.logButtonPressedAnalyticEvents(button: .messagingDataType, parameters: [.value: newSelectedDataType.rawValue])
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
    
    func showCurrentDataTypeRequests() {
        guard let profile = selectedProfileWalletPair?.profile,
              let nav = view?.cNavigationController else { return }
        
        switch selectedDataType {
        case .chats:
            let chatsList = getListOfUnblockedChats()
            let requests = chatsList.requestsOnly()
            guard !requests.isEmpty else { return }
            
            UDRouter().showChatRequestsScreen(dataType: .chatRequests(requests),
                                              profile: profile,
                                              in: nav)
        case .communities:
            return // TODO: - Communities
        case .channels:
            let channels = self.channels.filter { !$0.isCurrentUserSubscribed }
            guard !channels.isEmpty else { return }

            UDRouter().showChatRequestsScreen(dataType: .channelsSpam(channels),
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
            case .cancelled, .failed:
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
                let profile = try await messagingService.createUserMessagingProfile(for: domain)
                let isCommunitiesEnabled = await messagingService.isCommunitiesEnabled(for: profile)
                let isUDBlueEnabled = await getUDBlueEnabledStatus(for: domain)
                try await selectProfileWalletPair(.init(wallet: wallet,
                                                        profile: profile,
                                                        isCommunitiesEnabled: isCommunitiesEnabled,
                                                        isUDBlueEnabled: isUDBlueEnabled))
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
        }
    }
    
    func getUDBlueEnabledStatus(for domain: DomainDisplayInfo?) async -> Bool {
        guard let domain else { return false }
        let profile = try? await NetworkService().fetchPublicProfile(for: domain.name, fields: [.profile])
        return profile?.profile.udBlue == true
    }
}

// MARK: - Private methods
private extension ChatsListViewPresenter {
    struct ChatProfileWalletPair {
        let wallet: WalletDisplayInfo
        let profile: MessagingChatUserProfileDisplayInfo?
        let isCommunitiesEnabled: Bool
        let isUDBlueEnabled: Bool
    }
    
    struct SearchData {
        var isSearchActive = false
        var mode: ChatsList.SearchMode = .default
        var searchKey: String = ""
        var searchUsers: [MessagingChatUserDisplayInfo] = []
        var searchChannels: [MessagingNewsChannel] = []
        var domainProfiles: [SearchDomainProfile] = []
    }
    
    enum MessagingProfileStateAnalytics: String {
        case created
        case notCreatedRRSet
        case notCreatedRRNotSet
    }
    
    enum ChatsListError: Error {
        case noWalletsForChatting
    }
}
