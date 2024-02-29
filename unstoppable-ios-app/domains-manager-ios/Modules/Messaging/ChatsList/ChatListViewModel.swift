//
//  ChatListViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI
import Combine

@MainActor
final class ChatListViewModel: ObservableObject, ViewAnalyticsLogger {
    var analyticsName: Analytics.ViewName { .chatsHome }
    
    typealias ChatsListDataType = ChatsList.DataType
    
    private let fetchLimit: Int = 10
    private let messagingService: MessagingServiceProtocol
    private var presentOptions: ChatsList.PresentOptions
    
    private var selectedWallet: WalletEntity?
    private var wallets: [WalletEntity] = []
    private var profileWalletPairsCache: [ChatProfileWalletPair] = []
    private var selectedProfileWalletPair: ChatProfileWalletPair?
    private var didLoadTime = Date()
    
    private var chatsList: [MessagingChatDisplayInfo] = []
    private var communitiesList: [MessagingChatDisplayInfo] = []
    private var channels: [MessagingNewsChannel] = []
    private let searchManager = ChatsList.SearchManager(debounce: 0.3)
    private var didResolveInitialState = false
    private var cancellables: Set<AnyCancellable> = []
    @Published private(set) var selectedProfile: UserProfile
    @Published private(set) var isLoading = false
    @Published private(set) var chatState: ChatListView.ViewState = .loading
    @Published private(set) var searchData = SearchData()
    @Published private(set) var chatsListToShow: [MessagingChatDisplayInfo] = []
    @Published private(set) var chatsRequests: [MessagingChatDisplayInfo] = []
    @Published private(set) var communitiesListState: ChatListView.CommunitiesListState = .empty
    @Published private(set) var channelsToShow: [MessagingNewsChannel] = []
    @Published private(set) var channelsRequests: [MessagingNewsChannel] = []
    @Published private(set) var foundUsersToShow: [MessagingChatUserDisplayInfo] = []
    @Published var selectedDataType: ChatsList.DataType = .chats
    @Published var error: Error?
    @Published var isSearchActive: Bool = false
    @Published var searchText: String = ""
    @Published var searchMode: ChatsList.SearchMode = .default

    private var router: HomeTabRouter

    init(presentOptions: ChatsList.PresentOptions,
         router: HomeTabRouter,
         messagingService: MessagingServiceProtocol = appContext.messagingService) {
        self.presentOptions = presentOptions
        self.selectedProfile = router.profile
        if case .wallet(let wallet) = router.profile {
            selectedWallet = wallet
        }
        self.router = router
        self.messagingService = messagingService
        router.chatsListCoordinator = self
        appContext.userProfileService.selectedProfilePublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedProfile in
            guard self?.didResolveInitialState == true else { return }
            
            if case .wallet(let selectedWallet) = selectedProfile {
                self?.didSelectWallet(selectedWallet)
            } else {
                self?.setNoWalletsState()
            }
            if let selectedProfile {
                self?.selectedProfile = selectedProfile
            }
        }.store(in: &cancellables)
        appContext.walletsDataService.walletsPublisher.receive(on: DispatchQueue.main).sink { [weak self] wallets in
            self?.refreshAvailableWalletsList()
        }.store(in: &cancellables)
        $searchText.sink { [weak self] searchText in
            guard self?.didResolveInitialState == true else { return }

            self?.didSearchWith(key: searchText)
        }.store(in: &cancellables)
        $isSearchActive.sink { [weak self] isActive in
            guard self?.didResolveInitialState == true else { return }

            if !isActive {
                self?.didStopSearch()
            }
        }.store(in: &cancellables)
        
        messagingService.addListener(self)
        loadAndShowData()
    }
    
}

// MARK: - Open methods
extension ChatListViewModel {
    func didSelectUserToChat(_ user: MessagingChatUserDisplayInfo) {
        if let existingChat = chatsList.first(where: { $0.type.otherUserDisplayInfo?.wallet.normalized == user.wallet.normalized }) {
            openChatWith(conversationState: .existingChat(existingChat))
        } else {
            openChatWith(conversationState: .newChat(.init(userInfo: user, messagingService: messagingService.defaultServiceIdentifier)))
        }
    }
    
    func joinCommunity(_ community: MessagingChatDisplayInfo) {
        Task {
            isLoading = true
            do {
                let chat = try await messagingService.joinCommunityChat(community)
                openChatWith(conversationState: .existingChat(chat))
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func showChatRequests() {
        guard let profile = selectedProfileWalletPair?.profile else { return }

        stopSearching()
        router.chatTabNavPath.append(.requests(profile: profile,
                                               dataType: .chatRequests(chatsRequests)))
    }
    
    func showChannelRequests() {
        guard let profile = selectedProfileWalletPair?.profile else { return }

        stopSearching()
        router.chatTabNavPath.append(.requests(profile: profile,
                                               dataType: .channelsSpam(channelsRequests)))
    }

    func openChatWith(conversationState: MessagingChatConversationState) {
        guard let profile = selectedProfileWalletPair?.profile else { return }
        if case .existingChat(let messagingChatDisplayInfo) = conversationState,
           messagingChatDisplayInfo.isCommunityChat,
           !Constants.isCommunitiesEnabled {
            return
        }
        
        stopSearching()
        isSearchActive = false
        router.chatTabNavPath.append(HomeChatNavigationDestination.chat(profile: profile,
                                                                        conversationState: conversationState))
    }
    
    func openChannel(_ channel: MessagingNewsChannel) {
                guard let profile = selectedProfileWalletPair?.profile else { return }
        
        stopSearching()
        router.chatTabNavPath.append(HomeChatNavigationDestination.channel(profile: profile, channel: channel))
    }
    
    func createProfilePressed() {
        Task {
            guard let selectedProfileWalletPair,
                  let view = appContext.coreAppCoordinator.topVC else { return }
            
            do {
                try await appContext.authentificationService.verifyWith(uiHandler: view,
                                                                        purpose: .confirm)
                let wallet = selectedProfileWalletPair.wallet
                createProfileFor(in: wallet)
            } catch { }
        }
    }
    
    func addWalletButtonPressed() {
        router.runAddWalletFlow(initialAction: .showAllAddWalletOptionsPullUp)
    }
    
    func createCommunitiesProfileButtonPressed() {
        Task {
            guard let selectedProfileWalletPair,
                  let profile = selectedProfileWalletPair.profile,
                  let view = appContext.coreAppCoordinator.topVC else { return }
            
            do {
                try await appContext.authentificationService.verifyWith(uiHandler: view,
                                                                        purpose: .confirm)
                try await messagingService.createCommunityProfile(for: profile)
                try await selectProfileWalletPair(.init(wallet: selectedProfileWalletPair.wallet,
                                                        profile: profile,
                                                        isCommunitiesEnabled: true))
                appContext.toastMessageService.showToast(.communityProfileEnabled, isSticky: false)
            } catch {
                self.error = error
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
                                                                                                mode: searchMode,
                                                                                                page: 1,
                                                                                                limit: fetchLimit,
                                                                                                for: profile)
                searchData.searchUsers = searchUsers
                searchData.searchChannels = searchChannels
                searchData.domainProfiles = domainNames
                prepareData()
            } catch {
                self.error = error
            }
        }
    }
 
    func numberOfUnreadMessagesFor(dataType: ChatsList.DataType) -> Int {
        switch dataType {
        case .chats:
            chatsList.reduce(0, { $0 + $1.unreadMessagesCount })
        case .communities:
            communitiesList.reduce(0, { $0 + $1.unreadMessagesCount })
        case .channels:
            channels.reduce(0, { $0 + $1.unreadMessagesCount })
        }
    }
}

// MARK: - ChatsListCoordinator
extension ChatListViewModel: ChatsListCoordinator {
    func update(presentOptions: ChatsList.PresentOptions) {
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
                            let dataType = dataTypeFor(chatId: chatId)
                            try await prepareToAutoOpenWith(profile: profile, dataType: dataType)
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
                syncSelectedProfileWithMessaging()
            } catch {
                self.error = error
            }
        }
    }
    
    private func syncSelectedProfileWithMessaging() {
        switch selectedProfile {
        case .wallet(let wallet):
            if let selectedMessagingWallet = selectedProfileWalletPair?.wallet,
               wallet.address != selectedMessagingWallet.address  {
                appContext.userProfileService.setSelectedProfile(.wallet(selectedMessagingWallet))
            }
        case .webAccount:
            if let selectedMessagingWallet = selectedProfileWalletPair?.wallet {
                appContext.userProfileService.setSelectedProfile(.wallet(selectedMessagingWallet))
            }
        }
    }
    
    private func dataTypeFor(chatId: String) -> ChatsListDataType {
        communitiesList.first(where: { $0.id.contains(chatId) }) != nil ? .communities : .chats
    }
    
    private func popToChatsListAndWait() async {
        router.popToRoot()
        await Task.sleep(seconds: CNavigationController.animationDuration)
    }
}

// MARK: - MessagingServiceListener
extension ChatListViewModel: MessagingServiceListener {
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
                    prepareData()
                }
            case .channels(let channels, let profile):
                if case .showChannel(_, let showProfile) = presentOptions,
                   showProfile.id == profile.id {
                    loadAndShowData()
                } else if profile.id == selectedProfileWalletPair?.profile?.id {
                    self.channels = channels
                    prepareData()
                }
            case .messageReadStatusUpdated(let message, let numberOfUnreadMessagesInSameChat):
                if let profile = selectedProfileWalletPair?.profile,
                   await messagingService.isMessage(message, belongTo: profile) {
                    if let i = chatsList.firstIndex(where: { $0.id == message.chatId }) {
                        chatsList[i].unreadMessagesCount = numberOfUnreadMessagesInSameChat
                    } else if let i = communitiesList.firstIndex(where: { $0.id == message.chatId }) {
                        communitiesList[i].unreadMessagesCount = numberOfUnreadMessagesInSameChat
                    }
                    if numberOfUnreadMessagesInSameChat == 0 {
                        prepareData()
                    }
                }
            case .messageUpdated, .messagesRemoved, .messagesAdded, .channelFeedAdded, .totalUnreadMessagesCountUpdated, .refreshOfUserProfile, .userInfoRefreshed:
                return
            }
        }
    }
}

// MARK: - Private functions
private extension ChatListViewModel {
    func didStopSearch() {
        self.searchData = SearchData()
        didSearchWith(key: "")
        prepareData()
    }
    
    func didSelectWallet(_ wallet: WalletEntity) {
        guard wallet.address != selectedProfileWalletPair?.wallet.address else { return }
        
        self.selectedWallet = wallet
        runLoadingState()
        Task {
            if let cachedPair = profileWalletPairsCache.first(where: { $0.wallet.address == wallet.address }) {
                try await self.selectProfileWalletPair(cachedPair)
            } else {
                let profile = try? await messagingService.getUserMessagingProfile(for: wallet)
                let isCommunitiesEnabled = await isCommunitiesEnabled(for: profile)
                try await selectProfileWalletPair(.init(wallet: wallet,
                                                        profile: profile,
                                                        isCommunitiesEnabled: isCommunitiesEnabled))
            }
        }
    }
    
    func runLoadingState() {
        chatsList.removeAll()
        channels.removeAll()
        chatState = .loading
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
                        let dataType = dataTypeFor(chatId: chatId)
                        selectedDataType = dataType
                        prepareData()
                        tryAutoOpenChat(chatId, profile: profile)
                    case .newChat(let details):
                        autoOpenNewChat(with: details.userInfo, messagingService: details.messagingService)
                    }
                case .showChannel(let channelId, let profile):
                    try await prepareToAutoOpenWith(profile: profile, dataType: .channels)
                    tryAutoOpenChannel(channelId, profile: profile)
                }
            } catch ChatsListError.noWalletsForChatting {
              
            } catch {
                self.error = error
            }
            didResolveInitialState = true
        }
    }
    
    func prepareToAutoOpenWith(profile: MessagingChatUserProfileDisplayInfo,
                               dataType: ChatsListDataType) async throws {
        await popToChatsListAndWait()
        if selectedDataType != dataType {
            selectedDataType = dataType
            prepareData()
        }
        try await preselectProfile(profile, usingWallets: wallets)
    }
    
    func setNewChats(_ chats: [MessagingChatDisplayInfo]) {
        (chatsList, communitiesList) = chats.splitCommunitiesAndOthers()
    }
    
    func refreshAvailableWalletsList() {
        Task {
            do {
                wallets = try await loadReadyForChattingWalletsOrClose()
            } catch { }
        }
    }
    
    func loadReadyForChattingWalletsOrClose() async throws -> [WalletEntity] {
        let wallets = messagingService.fetchWalletsAvailableForMessaging()
        guard !wallets.isEmpty else {
            setNoWalletsState()
            throw ChatsListError.noWalletsForChatting
        }
        
        return wallets
    }
    
    func setNoWalletsState() {
        selectedWallet = nil
        selectedProfileWalletPair = nil
        chatState = .noWallet
        prepareData()
    }
    
    func isCommunitiesEnabled(for messagingProfile: MessagingChatUserProfileDisplayInfo?) async -> Bool {
        if let messagingProfile {
            return await messagingService.isCommunitiesEnabled(for: messagingProfile)
        }
        return false
    }
    
    func resolveInitialProfileWith(wallets: [WalletEntity]) async throws {
        guard let selectedWallet else {
            setNoWalletsState()
            return
        }
        
        let profile = try? await messagingService.getUserMessagingProfile(for: selectedWallet)
        let isCommunitiesEnabled = await isCommunitiesEnabled(for: profile)
        try await selectProfileWalletPair(.init(wallet: selectedWallet,
                                                profile: profile,
                                                isCommunitiesEnabled: isCommunitiesEnabled))
    }
    
    func preselectProfile(_ profile: MessagingChatUserProfileDisplayInfo,
                          usingWallets wallets: [WalletEntity]) async throws {
        guard let wallet = wallets.first(where: { $0.address == profile.wallet.lowercased() }) else {
            try await resolveInitialProfileWith(wallets: wallets)
            return
        }
        let isCommunitiesEnabled = await isCommunitiesEnabled(for: profile)
        try await selectProfileWalletPair(.init(wallet: wallet,
                                                profile: profile,
                                                isCommunitiesEnabled: isCommunitiesEnabled))
    }
    
    func tryAutoOpenChat(_ chatId: String, profile: MessagingChatUserProfileDisplayInfo) {
        var chat = chatsList.first(where: { $0.id.contains(chatId) })
        if let community = communitiesList.first(where: { $0.id.contains(chatId) }) {
            chat = community
        }
        guard let chat else { return }
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
            await Task.sleep(seconds: dif)
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
            let state: MessagingProfileStateAnalytics = chatProfile.wallet.rrDomain == nil ? .notCreatedRRNotSet : .notCreatedRRSet
            logAnalytic(event: .willShowMessagingProfile,
                        parameters: [.state : state.rawValue,
                                     .wallet: chatProfile.wallet.address])
            await awaitForUIReady()
            chatState = .createProfile
            prepareData()
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
        chatState = .chatsList
        prepareData()
        messagingService.setCurrentUser(profile)
    }
    
    func unreadMessagesCountFor(wallet: WalletEntity) -> Int? {
        profileWalletPairsCache.first(where: { $0.wallet.address == wallet.address })?.profile?.unreadMessagesCount
    }
    
    func prepareData() {
        Task {
            if selectedWallet == nil {
                chatState = .noWallet
            } else if selectedProfileWalletPair?.profile == nil {
                chatState = .createProfile
            } else {
                chatState = .chatsList
                if isSearchActive {
                    fillSnapshotForSearchActiveState()
                } else {
                    fillSnapshotForUserChatsList()
                    fillSnapshotForUserCommunitiesList()
                    fillSnapshotForUserChannelsList()
                }
            }
        }
    }
    
    func fillSnapshotForUserChatsList() {
        chatsRequests = chatsList.requestsOnly()
        chatsListToShow = chatsList.confirmedOnly().unblockedOnly()
    }
  
    func fillSnapshotForUserCommunitiesList() {
        let communitiesList = communitiesList.unblockedOnly()
        
        if selectedProfileWalletPair?.isCommunitiesEnabled != true {
            communitiesListState = .noProfile
        } else {
            if communitiesList.isEmpty {
                communitiesListState = .empty
            } else {
                let groupedCommunities = groupCommunitiesByJoinStatus(communitiesList)
                
                if !groupedCommunities.joined.isEmpty {
                    // With title
                    communitiesListState = .mixed(joined: groupedCommunities.joined,
                                                  notJoined: groupedCommunities.notJoined)
                } else {
                    communitiesListState = .notJoinedOnly(groupedCommunities.notJoined)
                }
            }
        }
    }

    typealias GroupedCommunities = (joined: [MessagingChatDisplayInfo], notJoined: [MessagingChatDisplayInfo])
    
    func groupCommunitiesByJoinStatus(_ communities: [MessagingChatDisplayInfo]) -> GroupedCommunities {
        communities.reduce(into: GroupedCommunities([], [])) { result, element in
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
    }
    
    func fillSnapshotForUserChannelsList() {
        channelsToShow = channels.filter({ $0.isCurrentUserSubscribed })
        channelsRequests = channels.filter({ !$0.isCurrentUserSubscribed })
    }
    
    func fillSnapshotForSearchActiveState() {
        enum PeopleSearchResult {
            case existingChat(MessagingChatDisplayInfo)
            case newUser(MessagingChatUserDisplayInfo)
        }
        let searchKey = searchData.searchKey.trimmedSpaces.lowercased()
        
        var people = [PeopleSearchResult]()
        var communities = [MessagingChatDisplayInfo]()
        var channels = [MessagingNewsChannel]()
        if searchKey.isEmpty {
            people = chatsList.map({ .existingChat($0) })
            communities = communitiesList
            channels = self.channels
        } else {
            /// Chats
            // Local chats
            let localChats = chatsList.filter { isChatMatchingSearchKey($0, searchKey: searchKey) }
            var localChatsPeopleWallets = Set(localChats.compactMap { $0.type.otherUserDisplayInfo?.wallet.lowercased() })
            localChatsPeopleWallets.insert(selectedProfileWalletPair?.wallet.address.lowercased() ?? "")
            people = localChats.map { .existingChat($0) }
            
            // Domain profiles
            let domainProfiles = searchData.domainProfiles.filter({ $0.ownerAddress != nil && $0.name != selectedProfileWalletPair?.wallet.rrDomain?.name && !localChatsPeopleWallets.contains($0.ownerAddress!.lowercased()) })
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
            
            /// Communities
            communities = communitiesList.filter { isChatMatchingSearchKey($0, searchKey: searchKey)}
            
            /// Channels
            let localChannels = self.channels.filter { $0.name.lowercased().contains(searchKey) }
            let subscribedChannelsIds = self.channels.map { $0.id }
            let remoteChannels = searchData.searchChannels.filter { !subscribedChannelsIds.contains($0.id) }
            channels = localChannels + remoteChannels
        }
        
        switch searchMode {
        case .default:
            Void()
        case .chatsOnly:
            channels.removeAll()
            communities.removeAll()
        case .channelsOnly:
            people.removeAll()
            communities.removeAll()
        }
        
        
        var foundUsers: [MessagingChatUserDisplayInfo] = []
        var chats: [MessagingChatDisplayInfo] = []
        
        for person in people {
            switch person {
            case .existingChat(let chat):
                chats.append(chat)
            case .newUser(let user):
                foundUsers.append(user)
            }
        }
        
        self.foundUsersToShow = foundUsers
        self.chatsListToShow = chats
        if communities.isEmpty {
            communitiesListState = .empty
        } else {
            let groupedCommunities = groupCommunitiesByJoinStatus(communities)
            communitiesListState = .mixed(joined: groupedCommunities.joined, notJoined: groupedCommunities.notJoined)
        }
        
        channelsToShow = channels
    }
    
    func isChatMatchingSearchKey(_ chat: MessagingChatDisplayInfo, searchKey: String) -> Bool {
        switch chat.type {
        case .private(let details):
            return isUserMatchSearchKey(details.otherUser, searchKey: searchKey)
        case .group(let details):
            let members = details.allMembers
            return members.first(where: { isUserMatchSearchKey($0, searchKey: searchKey) }) != nil
        case .community(let details):
            return details.displayName.lowercased().contains(searchKey)
        }
    }
    
    func isUserMatchSearchKey(_ user: MessagingChatUserDisplayInfo, searchKey: String) -> Bool {
        if user.wallet.lowercased().contains(searchKey) {
            return true
        }
        return user.domainName?.lowercased().contains(searchKey) == true
    }
    
    func createProfileFor(in wallet: WalletEntity) {
        Task {
            do {
                let profile = try await messagingService.createUserMessagingProfile(for: wallet)
                let isCommunitiesEnabled = await messagingService.isCommunitiesEnabled(for: profile)
                try await selectProfileWalletPair(.init(wallet: wallet,
                                                        profile: profile,
                                                        isCommunitiesEnabled: isCommunitiesEnabled))
            } catch {
                self.error = error
            }
        }
    }
    
    func stopSearching() {
        isSearchActive = false
        searchText = ""
    }
}

// MARK: - Private methods
private extension ChatListViewModel {
    struct ChatProfileWalletPair {
        let wallet: WalletEntity
        let profile: MessagingChatUserProfileDisplayInfo?
        let isCommunitiesEnabled: Bool
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

// MARK: - Open methods
extension ChatListViewModel {
    struct SearchData {
        var searchKey: String = ""
        var searchUsers: [MessagingChatUserDisplayInfo] = []
        var searchChannels: [MessagingNewsChannel] = []
        var domainProfiles: [SearchDomainProfile] = []
    }
}
