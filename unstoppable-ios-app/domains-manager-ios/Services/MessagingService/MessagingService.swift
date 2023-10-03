//
//  MessagingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

struct MessagingServiceAPIProvider {
    let identifier: MessagingServiceIdentifier
    let apiService: MessagingAPIServiceProtocol
    let webSocketsService: MessagingWebSocketsServiceProtocol
}

final class MessagingService {

    let serviceProviders: [MessagingServiceAPIProvider]
    let channelsApiService: MessagingChannelsAPIServiceProtocol
    let channelsWebSocketsService: MessagingChannelsWebSocketsServiceProtocol
    let storageService: MessagingStorageServiceProtocol
    let decrypterService: MessagingContentDecrypterService
    let filesService: MessagingFilesServiceProtocol
    let unreadCountingService: MessagingUnreadCountingServiceProtocol
    
    let dataRefreshManager = MessagingServiceDataRefreshManager()
    /// By default and as primary service we use XMTP
    let defaultServiceIdentifier: MessagingServiceIdentifier = .xmtp
    let communitiesServiceIdentifier: MessagingServiceIdentifier = .push
    private(set) var listenerHolders: [MessagingListenerHolder] = []
    private(set) var currentUser: MessagingChatUserProfileDisplayInfo?
    
    private(set) var stateHolder = StateHolder()

    init(serviceProviders: [MessagingServiceAPIProvider],
         channelsApiService: MessagingChannelsAPIServiceProtocol,
         channelsWebSocketsService: MessagingChannelsWebSocketsServiceProtocol,
         storageProtocol: MessagingStorageServiceProtocol,
         decrypterService: MessagingContentDecrypterService,
         filesService: MessagingFilesServiceProtocol,
         unreadCountingService: MessagingUnreadCountingServiceProtocol,
         udWalletsService: UDWalletsServiceProtocol) {
        self.serviceProviders = serviceProviders
        self.channelsApiService = channelsApiService
        self.channelsWebSocketsService = channelsWebSocketsService
        self.storageService = storageProtocol
        self.decrypterService = decrypterService
        self.filesService = filesService
        self.unreadCountingService = unreadCountingService
        udWalletsService.addListener(self)
        
        storageService.markSendingMessagesAsFailed()
        setSceneActivationListener()
        dataRefreshManager.delegate = self
        unreadCountingService.totalUnreadMessagesCountUpdated = { [weak self] val in self?.totalUnreadMessagesCountUpdated(val) }
        preloadLastUsedProfile()
    }
    
}

// MARK: - MessagingServiceProtocol
extension MessagingService: MessagingServiceProtocol {
    // Capabilities
    func canContactWithoutProfile(using messagingService: MessagingServiceIdentifier) -> Bool {
        guard let apiService = try? getAPIServiceWith(identifier: messagingService) else { return false }

        return apiService.capabilities.canContactWithoutProfile
    }
    
    func canBlockUsers(in chat: MessagingChatDisplayInfo) -> Bool {
        guard let apiService = try? getAPIServiceWith(identifier: chat.serviceIdentifier) else { return false }
        return apiService.capabilities.canBlockUsers
    }
    
    func isAbleToContactAddress(_ address: String,
                                by user: MessagingChatUserProfileDisplayInfo) async throws -> Bool {
        let profile = try storageService.getUserProfileWith(userId: user.id,
                                                            serviceIdentifier: user.serviceIdentifier)
        let apiService = try getAPIServiceWith(identifier: user.serviceIdentifier)
        return try await apiService.isAbleToContactAddress(address, by: profile)
    }
    
    func fetchWalletsAvailableForMessaging() async -> [WalletDisplayInfo] {
        let domains = await appContext.dataAggregatorService.getDomainsDisplayInfo()
        let wallets = await appContext.dataAggregatorService.getWalletsWithInfo()
            .compactMap { walletWithInfo -> WalletDisplayInfo? in
                let walletDomains = domains.filter { walletWithInfo.wallet.owns(domain: $0) }
                let applicableDomains = walletDomains.availableForMessagingItems()
                if applicableDomains.isEmpty {
                    return nil
                }
                var walletDisplayInfo = walletWithInfo.displayInfo
                if walletDisplayInfo?.reverseResolutionDomain == nil,
                   applicableDomains.first(where: { $0.isUDDomain }) == nil {
                    /// If wallet doesn't have any UNS domain, we still allow to chat as other (ENS only for now) domain
                    walletDisplayInfo?.reverseResolutionDomain = applicableDomains.first
                }
                return walletDisplayInfo
            }
            .sorted(by: {
                if $0.reverseResolutionDomain == nil && $1.reverseResolutionDomain != nil {
                    return false
                } else if $0.reverseResolutionDomain != nil && $1.reverseResolutionDomain == nil {
                    return true
                }
                return $0.domainsCount > $1.domainsCount
            })
        
        return wallets
    }
    
    func getLastUsedMessagingProfile(among givenWallets: [WalletDisplayInfo]?) async -> MessagingChatUserProfileDisplayInfo? {
        let wallets: [WalletDisplayInfo]
        
        if let givenWallets {
            wallets = givenWallets
        } else {
            wallets = await fetchWalletsAvailableForMessaging()
        }
        
        if let apiService = try? getDefaultAPIService(),
           let lastUsedWallet = UserDefaults.currentMessagingOwnerWallet,
           let wallet = wallets.first(where: { $0.address == lastUsedWallet }),
           let rrDomain = wallet.reverseResolutionDomain,
           let domain = try? await appContext.dataAggregatorService.getDomainWith(name: rrDomain.name),
           let profile = try? storageService.getUserProfileFor(domain: domain,
                                                               serviceIdentifier: apiService.serviceIdentifier) {
            /// User already used chat with some profile, select last used.
            //                try await selectProfileWalletPair(.init(wallet: wallet,
            //                                                        profile: profile))
            return profile.displayInfo
        }
        return nil
    }
    
    // User
    func getUserMessagingProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo {
        try await getUserProfile(for: domain, serviceIdentifier: defaultServiceIdentifier)
    }
 
    func createUserMessagingProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo {
        try await createUserProfile(for: domain, serviceIdentifier: defaultServiceIdentifier)
    }
    
    func getUserCommunitiesProfile(for messagingProfile: MessagingChatUserProfileDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo {
        let wallet = messagingProfile.wallet
        let domain = try await getReverseResolutionDomainItem(for: wallet)
        return try await getUserProfileFor(domainItem: domain, serviceIdentifier: messagingProfile.serviceIdentifier)
    }
    
    func getUserCommunitiesProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo {
        try await getUserProfile(for: domain, serviceIdentifier: communitiesServiceIdentifier)
    }
    
    func createUserCommunitiesProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo {
        try await createUserProfile(for: domain, serviceIdentifier: communitiesServiceIdentifier)
    }
    
    func setCurrentUser(_ userProfile: MessagingChatUserProfileDisplayInfo?) {
        self.currentUser = userProfile
        refreshMessagingInfoFor(userProfile: userProfile, shouldRefreshUserInfo: true)
    }
    
    func isUpdatingUserData(_ userProfile: MessagingChatUserProfileDisplayInfo) -> Bool {
        dataRefreshManager.isUpdatingUserData(userProfile)
    }
    
    func isNewMessagesAvailable() async throws -> Bool {
        let apiService = try getDefaultAPIService()
        let totalNumberOfUnreadMessages = unreadCountingService.getTotalNumberOfUnreadMessages()
        if totalNumberOfUnreadMessages > 0 {
            return true
        }
        
        let wallets = await appContext.dataAggregatorService.getWalletsWithInfo()
        
        for wallet in wallets {
            guard let rrDomain = wallet.displayInfo?.reverseResolutionDomain,
                  let domain = try? await appContext.dataAggregatorService.getDomainWith(name: rrDomain.name),
                  let cachedProfile = try? storageService.getUserProfileFor(domain: domain,
                                                                            serviceIdentifier: apiService.serviceIdentifier) else { continue }
            
            let isNewMessagesForProfileAvailable = try? await isNewMessagesAvailable(for: cachedProfile)
            if isNewMessagesForProfileAvailable == true {
                return true
            }
        }
        
        return false
    }
    
    // Chats list
    func getChatsListForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingChatDisplayInfo] {
        let profile = try await getUserProfileWith(wallet: profile.wallet, serviceIdentifier: profile.serviceIdentifier)
        let chats = try await storageService.getChatsFor(profile: profile)
        
        let chatsDisplayInfo = chats.map { $0.displayInfo }
        return chatsDisplayInfo
    }
    
    func makeChatRequest(_ chat: MessagingChatDisplayInfo, approved: Bool) async throws {
        let serviceIdentifier = chat.serviceIdentifier
        let profile = try await getUserProfileWith(wallet: chat.thisUserDetails.wallet, serviceIdentifier: serviceIdentifier)
        let apiService = try getAPIServiceWith(identifier: serviceIdentifier)
        var chat = try await getMessagingChatFor(displayInfo: chat, userId: profile.id)
        try await apiService.makeChatRequest(chat, approved: approved, by: profile)
        chat.displayInfo.isApproved = approved
        await storageService.saveChats([chat])
        notifyChatsChanged(wallet: profile.wallet, serviceIdentifier: serviceIdentifier)
        refreshChatsForProfile(profile, shouldRefreshUserInfo: false)
    }
    
    func leaveGroupChat(_ chat: MessagingChatDisplayInfo) async throws {
        guard case .group = chat.type else { throw MessagingServiceError.attemptToLeaveNotGroupChat }
        
        let serviceIdentifier = chat.serviceIdentifier
        let profile = try await getUserProfileWith(wallet: chat.thisUserDetails.wallet, serviceIdentifier: serviceIdentifier)
        let chat = try await getMessagingChatFor(displayInfo: chat, userId: profile.id)

        let apiService = try getAPIServiceWith(identifier: serviceIdentifier)
        try await apiService.leaveGroupChat(chat, by: profile)
        storageService.deleteChat(chat, filesService: filesService)
        notifyChatsChanged(wallet: profile.wallet, serviceIdentifier: serviceIdentifier)
    }
    
    func getCachedBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) -> MessagingPrivateChatBlockingStatus {
        guard let apiService = try? getAPIServiceWith(identifier: chat.serviceIdentifier) else { return .unblocked }
        return apiService.getCachedBlockingStatusForChat(chat)
    }
    
    func getBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) async throws -> MessagingPrivateChatBlockingStatus {
        let serviceIdentifier = chat.serviceIdentifier
        let apiService = try getAPIServiceWith(identifier: serviceIdentifier)
        let profile = try await getUserProfileWith(wallet: chat.thisUserDetails.wallet, serviceIdentifier: serviceIdentifier)
        let chat = try await getMessagingChatFor(displayInfo: chat, userId: profile.id)
        
        return try await apiService.getBlockingStatusForChat(chat)
    }
    
    func setUser(in chat: MessagingChatDisplayInfo,
                 blocked: Bool) async throws {
        let serviceIdentifier = chat.serviceIdentifier
        let apiService = try getAPIServiceWith(identifier: serviceIdentifier)
        let profile = try await getUserProfileWith(wallet: chat.thisUserDetails.wallet, serviceIdentifier: serviceIdentifier)
        let chat = try await getMessagingChatFor(displayInfo: chat, userId: profile.id)

        try await apiService.setUser(in: chat, blocked: blocked, by: profile)
        if Constants.shouldHideBlockedUsersLocally {
            try? await storageService.markAllMessagesIn(chat: chat, isRead: true)
            notifyChatsChanged(wallet: profile.wallet, serviceIdentifier: serviceIdentifier)
        }
    }
    
    // Messages
    func getMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo,
                            before message: MessagingChatMessageDisplayInfo?,
                            cachedOnly: Bool,
                            limit: Int) async throws -> [MessagingChatMessageDisplayInfo] {
        let startTime = Date()
        if let message,
           message.isFirstInChat {
            return [] // There's no messages before this message
        }
        
        let serviceIdentifier = chatDisplayInfo.serviceIdentifier
        let apiService = try getAPIServiceWith(identifier: serviceIdentifier)
        let profile = try await getUserProfileWith(wallet: chatDisplayInfo.thisUserDetails.wallet, serviceIdentifier: serviceIdentifier)
        let chat = try await getMessagingChatFor(displayInfo: chatDisplayInfo, userId: profile.id)
        let cachedMessages = try await storageService.getMessagesFor(chat: chat,
                                                                     before: message,
                                                                     limit: limit)
        if cachedOnly {
            return cachedMessages.map { $0.displayInfo }
        }

        var chatMessage: MessagingChatMessage?
        if let message {
            chatMessage = await storageService.getMessageWith(id: message.id,
                                                              in: chat)
        }
        
        let messages = try await apiService.getMessagesForChat(chat,
                                                               before: chatMessage,
                                                               cachedMessages: cachedMessages,
                                                               fetchLimit: limit,
                                                               isRead: true,
                                                               for: profile,
                                                               filesService: filesService)
        Debugger.printTimeSensitiveInfo(topic: .Messaging,
                                        "to fetch \(messages.count) messages",
                                        startDate: startTime,
                                        timeout: 3)

        await storageService.saveMessages(messages)
        return messages.map { $0.displayInfo }
    }
    
    func loadRemoteContentFor(_ message: MessagingChatMessageDisplayInfo,
                              in chat: MessagingChatDisplayInfo) async throws -> MessagingChatMessageDisplayInfo {
        guard let messagingChat = await storageService.getChatWith(id: message.chatId, of: message.userId, serviceIdentifier: chat.serviceIdentifier),
              var chatMessage = await storageService.getMessageWith(id: message.id, in: messagingChat) else {
            throw MessagingServiceError.messageNotFound
        }
        let serviceIdentifier = chat.serviceIdentifier
        let apiService = try getAPIServiceWith(identifier: serviceIdentifier)
        let profile = try await getUserProfileWith(wallet: chat.thisUserDetails.wallet, serviceIdentifier: serviceIdentifier)

        switch chatMessage.displayInfo.type {
        case .text, .imageData, .imageBase64, .unknown:
            return message
        case .remoteContent(let info):
            let loadedType = try await apiService.loadRemoteContentFor(chatMessage,
                                                                       user: profile,
                                                                       serviceData: info.serviceData,
                                                                       filesService: filesService)
            chatMessage.displayInfo.type = loadedType
            await storageService.saveMessages([chatMessage])
            return chatMessage.displayInfo
        }
    }

    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     isEncrypted: Bool,
                     in chat: MessagingChatDisplayInfo) async throws -> MessagingChatMessageDisplayInfo {
        let serviceIdentifier = chat.serviceIdentifier
        let profile = try await getUserProfileWith(wallet: chat.thisUserDetails.wallet, serviceIdentifier: serviceIdentifier)
        let messagingChat = try await getMessagingChatFor(displayInfo: chat, userId: profile.id)
        let newMessageDisplayInfo = MessagingChatMessageDisplayInfo(id: UUID().uuidString,
                                                                    chatId: chat.id,
                                                                    userId: profile.id,
                                                                    senderType: .thisUser(chat.thisUserDetails),
                                                                    time: Date(),
                                                                    type: messageType,
                                                                    isRead: true,
                                                                    isFirstInChat: false,
                                                                    deliveryState: .sending,
                                                                    isEncrypted: isEncrypted)
        let message = MessagingChatMessage(displayInfo: newMessageDisplayInfo,
                                           serviceMetadata: nil)
        await storageService.saveMessages([message])
        
        try await setLastMessageAndNotify(newMessageDisplayInfo,
                                          to: messagingChat)
        let newMessage = MessagingChatMessage(displayInfo: newMessageDisplayInfo,
                                              serviceMetadata: nil)
        sendMessageToBEAsync(message: newMessage, messageType: messageType, in: messagingChat, by: profile)

        return newMessageDisplayInfo
    }
    
    func isMessagesEncryptedIn(conversation: MessagingChatConversationState) async throws -> Bool {
        switch conversation {
        case .existingChat(let chat):
            let apiService = try getAPIServiceWith(identifier: chat.serviceIdentifier)
            return await apiService.isMessagesEncryptedIn(chatType: chat.type)
        case .newChat(let description):
            let apiService = try getAPIServiceWith(identifier: description.messagingService)
            return await apiService.isMessagesEncryptedIn(chatType: .private(.init(otherUser: description.userInfo)))
        }
    }
    
    func sendFirstMessage(_ messageType: MessagingChatMessageDisplayType,
                          to userInfo: MessagingChatUserDisplayInfo,
                          by profile: MessagingChatUserProfileDisplayInfo) async throws -> (MessagingChatDisplayInfo, MessagingChatMessageDisplayInfo) {
        let serviceIdentifier = profile.serviceIdentifier
        let profile = try await getUserProfileWith(wallet: profile.wallet, serviceIdentifier: serviceIdentifier)
        let apiService = try getAPIServiceWith(identifier: serviceIdentifier)
        var (chat, message) = try await apiService.sendFirstMessage(messageType,
                                                                    to: userInfo,
                                                                    by: profile,
                                                                    filesService: filesService)
        switch chat.displayInfo.type {
        case .private(let infoInChat):
            var userInfo = userInfo
            userInfo.wallet = infoInChat.otherUser.wallet
            await storageService.saveMessagingUserInfo(userInfo)
            chat.displayInfo.type = .private(.init(otherUser: userInfo))
        case .group, .community: // TODO: - Communities
            Void()
        }
        await storageService.saveChats([chat])
        await storageService.saveMessages([message])
        try? await setLastMessageAndNotify(message.displayInfo, to: chat)
        
        return (chat.displayInfo, message.displayInfo)
    }

    func resendMessage(_ message: MessagingChatMessageDisplayInfo,
                       in chatDisplayInfo: MessagingChatDisplayInfo) async throws {
        let messagingChat = try await getMessagingChatFor(displayInfo: chatDisplayInfo, userId: message.userId)
        let profile = try await getUserProfileWith(wallet: messagingChat.displayInfo.thisUserDetails.wallet, serviceIdentifier: messagingChat.serviceIdentifier)
        var updatedMessage = message
        updatedMessage.deliveryState = .sending
        updatedMessage.time = Date()
        let newMessage = MessagingChatMessage(displayInfo: updatedMessage,
                                              serviceMetadata: nil)

        replaceCacheMessageAndNotify(.init(displayInfo: message,
                                           serviceMetadata: nil),
                                     with: newMessage)
        sendMessageToBEAsync(message: newMessage, messageType: updatedMessage.type, in: messagingChat, by: profile)
    }
    
    func deleteMessage(_ message: MessagingChatMessageDisplayInfo,
                       in chatDisplayInfo: MessagingChatDisplayInfo) async throws {
        let messagingChat = try await getMessagingChatFor(displayInfo: chatDisplayInfo, userId: message.userId)
        let isLastMessageInChat = messagingChat.displayInfo.lastMessage?.id == message.id
        storageService.deleteMessage(message)
        if isLastMessageInChat {
            guard let newLastMessage = (try await storageService.getMessagesFor(chat: messagingChat,
                                                                                before: nil,
                                                                                limit: 1)).first else { return }
            
            try await setLastMessageAndNotify(newLastMessage.displayInfo, to: messagingChat)
        }
    }
    
    func markMessage(_ message: MessagingChatMessageDisplayInfo,
                     isRead: Bool,
                     wallet: String) throws {
        try storageService.markMessage(message, isRead: isRead)
        notifyReadStatusUpdatedFor(message: message)
    }
   
    func decryptedContentURLFor(message: MessagingChatMessageDisplayInfo) async -> URL? {
        await filesService.decryptedContentURLFor(message: message)
    }
    
    // Channels
    func getChannelsForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel] {
        let profile = try await getUserProfileWith(wallet: profile.wallet, serviceIdentifier: profile.serviceIdentifier)
        let channels = try await storageService.getChannelsFor(profile: profile)
        return channels
    }
    
    func getFeedFor(channel: MessagingNewsChannel,
                    cachedOnly: Bool,
                    page: Int,
                    limit: Int) async throws -> [MessagingNewsChannelFeed] {
        if cachedOnly {
            let storedFeed = try await storageService.getChannelsFeedFor(channel: channel,
                                                                         page: page,
                                                                         limit: limit)
    
            return storedFeed
        }
        
        let startTime = Date()
        var feed = try await channelsApiService.getFeedFor(channel: channel,
                                                           page: page,
                                                           limit: limit,
                                                           isRead: true)
        Debugger.printTimeSensitiveInfo(topic: .Messaging,
                                        "to fetch \(feed.count) feed",
                                        startDate: startTime,
                                        timeout: 3)
        // Set first in channel for optimisation
        if feed.count < limit {
            if var lastFeed = feed.last {
                lastFeed.isFirstInChannel = true
                feed[feed.count - 1] = lastFeed
            }
        }
        
        // Store if subscribed
        if channel.isCurrentUserSubscribed {
            await storageService.saveChannelsFeed(feed,
                                                  in: channel)
        }
        
        return feed
    }
    
    func markFeedItem(_ feedItem: MessagingNewsChannelFeed,
                      isRead: Bool,
                      in channel: MessagingNewsChannel) throws {
        try storageService.markFeedItem(feedItem, isRead: isRead)
        notifyChannelsChanged(userId: channel.userId)
    }
    
    func setChannel(_ channel: MessagingNewsChannel,
                    subscribed: Bool,
                    by user: MessagingChatUserProfileDisplayInfo) async throws {
        let profile = try await getUserProfileWith(wallet: user.wallet, serviceIdentifier: defaultServiceIdentifier)
        try await channelsApiService.setChannel(channel, subscribed: subscribed, by: profile)
        var channel = channel
        channel.isCurrentUserSubscribed = subscribed
        if subscribed {
            channel.isSearchResult = false
            let updatedChannel = await refreshChannelsMetadata([channel], storedChannels: [])
            await storageService.saveChannels(updatedChannel, for: profile)
        } else {
            storageService.deleteChannel(channel)
        }
        
        notifyChannelsChanged(userId: user.id)
    }
    
    // Search
    func searchForUsersWith(searchKey: String) async throws -> [MessagingChatUserDisplayInfo] {
        if searchKey.isValidAddress() {
            let wallet = searchKey
            if let userInfo = await loadUserInfoFor(wallet: wallet) {
                return [userInfo]
            }
            
            return [.init(wallet: wallet)]
        } else if searchKey.isValidDomainNameForMessagingSearch(),
                  var userInfo = await loadGlobalUserInfoFor(value: searchKey) {
            if userInfo.isUDDomain,
               let userRRDomain = try? await appContext.udWalletsService.reverseResolutionDomainName(for: userInfo.wallet.normalized),
               userRRDomain != userInfo.domainName {
                // RR domain does not match
                userInfo.rrDomainName = userRRDomain
                Debugger.printInfo(topic: .Messaging, "Searched UD domain name \(userInfo.domainName ?? "") does not match RR domain name \(userRRDomain). Will suggest RR in search result.")
            }
            return [userInfo]
        }
        return []
    }
    
    func searchForChannelsWith(page: Int,
                               limit: Int,
                               searchKey: String,
                               for user: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel] {
        let profile = try await getUserProfileWith(wallet: user.wallet, serviceIdentifier: defaultServiceIdentifier)
        let channels = try await channelsApiService.searchForChannels(page: page, limit: limit, searchKey: searchKey, for: profile)
        
        return channels
    }
    
    // Listeners
    func addListener(_ listener: MessagingServiceListener) {
        if !listenerHolders.contains(where: { $0.listener === listener }) {
            listenerHolders.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: MessagingServiceListener) {
        listenerHolders.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - MessagingServiceDataRefreshManagerDelegate
extension MessagingService: MessagingServiceDataRefreshManagerDelegate {
    func didStartUpdatingProfile(_ userProfile: MessagingChatUserProfileDisplayInfo) {
        notifyListenersUsersUpdateOf(userProfile: userProfile, isInProgress: true)
    }
    
    func didFinishUpdatingProfile(_ userProfile: MessagingChatUserProfileDisplayInfo) {
        notifyListenersUsersUpdateOf(userProfile: userProfile, isInProgress: false)
    }
    
    private func notifyListenersUsersUpdateOf(userProfile: MessagingChatUserProfileDisplayInfo, isInProgress: Bool) {
        notifyListenersChangedDataType(.refreshOfUserProfile(userProfile, isInProgress: isInProgress))
    }
}

// MARK: - UDWalletsServiceListener
extension MessagingService: UDWalletsServiceListener {
    func walletsDataUpdated(notification: UDWalletsServiceNotification) {
        Task {
            switch notification {
            case .walletsUpdated, .reverseResolutionDomainChanged:
                return
            case .walletRemoved(let wallet):
                if let rrDomainName = await appContext.dataAggregatorService.getReverseResolutionDomain(for: wallet.address),
                   let rrDomain = try? await appContext.dataAggregatorService.getDomainWith(name: rrDomainName) {
                    for serviceProvider in serviceProviders {
                        if let profile = try? storageService.getUserProfileFor(domain: rrDomain, serviceIdentifier: serviceProvider.identifier) {
                            await storageService.clearAllDataOf(profile: profile, filesService: filesService)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - SceneActivationListener
extension MessagingService: SceneActivationListener {
    func didChangeSceneActivationState(to state: SceneActivationState) {
        switch state {
        case .foregroundActive:
            guard let currentUser else { return }
            
            refreshMessagingInfoFor(userProfile: currentUser, shouldRefreshUserInfo: false)
        case .background:
            disconnectAllSocketsConnections()
        case .foregroundInactive, .unattached:
            return
        @unknown default:
            return
        }
    }
}

// MARK: - Private methods
private extension MessagingService {
    func refreshMessagingInfoFor(userProfile: MessagingChatUserProfileDisplayInfo?,
                                 shouldRefreshUserInfo: Bool) {
        Task {
            do {
                if let userProfile {
                    let rrDomain = try await getReverseResolutionDomainItem(for: userProfile.wallet)
                    let profile = try storageService.getUserProfileFor(domain: rrDomain,
                                                                       serviceIdentifier: userProfile.serviceIdentifier)
                    if !dataRefreshManager.isUpdatingUserData(profile.displayInfo) {
                        refreshChatsForProfile(profile, shouldRefreshUserInfo: shouldRefreshUserInfo)
                        refreshChannelsForProfile(profile)
                    }

                    setupSocketConnection(profile: profile)
                } else {
                    disconnectAllSocketsConnections()
                }
            } catch { }
        }
    }
}

// MARK: - Private methods
private extension MessagingService {
    func sendMessageToBEAsync(message: MessagingChatMessage,
                              messageType: MessagingChatMessageDisplayType,
                              in chat: MessagingChat,
                              by user: MessagingChatUserProfile) {
        Task {
            await stateHolder.willStartToSendMessage()
            do {
                let apiService = try getAPIServiceWith(identifier: user.serviceIdentifier)

                var sentMessage = try await apiService.sendMessage(messageType,
                                                                   in: chat,
                                                                   by: user,
                                                                   filesService: filesService)
                sentMessage.displayInfo.type = messageType
                replaceCacheMessageAndNotify(message,
                                             with: sentMessage)
                try await setLastMessageAndNotify(sentMessage.displayInfo,
                                                  to: chat)
            } catch {
                var failedMessage = message
                failedMessage.displayInfo.deliveryState = .failedToSend
                replaceCacheMessageAndNotify(message,
                                             with: failedMessage)
            }
            await stateHolder.didSendMessage()
        }
    }
    
    func setSceneActivationListener() {
        Task { @MainActor in
            SceneDelegate.shared?.addListener(self)
        }
    }
 
    func totalUnreadMessagesCountUpdated(_ havingUnreadMessages: Bool) {
        notifyListenersChangedDataType(.totalUnreadMessagesCountUpdated(havingUnreadMessages))
    }
    
    func preloadLastUsedProfile() {
        Task {
            try? await Task.sleep(seconds: 0.5)
            if let lastUsedProfile = await getLastUsedMessagingProfile(among: nil) {
                setCurrentUser(lastUsedProfile)
            }
        }
    }
}

// MARK: - Open methods
extension MessagingService {
    enum MessagingServiceError: String, LocalizedError {
        case domainWithoutWallet
        case chatNotFound
        case messageNotFound
        case noRRDomainForProfile
        case failedToConvertWebsocketMessage
        case attemptToLeaveNotGroupChat
        case failedToFindRequestedServiceProvider
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}

// MARK: - StateHolder
extension MessagingService {
    actor StateHolder {
        
        private var sendingMessagesCounter: Int = 0
        
        var isSendingMessage: Bool { sendingMessagesCounter > 0 }
        
        func willStartToSendMessage() {
            sendingMessagesCounter += 1
            Debugger.printInfo(topic: .Messaging, "Will inrecase send message counter to \(sendingMessagesCounter)")
        }
        
        func didSendMessage() {
            sendingMessagesCounter -= 1
            Debugger.printInfo(topic: .Messaging, "Will decrease send message counter to \(sendingMessagesCounter)")
            if sendingMessagesCounter < 0 {
                Debugger.printFailure("Unmatched call to send message", critical: true)
            }
        }
        
    }
}
