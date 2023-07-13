//
//  MessagingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

final class MessagingService {

    private let apiService: MessagingAPIServiceProtocol
    private let webSocketsService: MessagingWebSocketsServiceProtocol
    private let storageService: MessagingStorageServiceProtocol
    private let decrypterService: MessagingContentDecrypterService
    private let filesService: MessagingFilesServiceProtocol
        
    private var listenerHolders: [MessagingListenerHolder] = []
    private var currentUser: MessagingChatUserProfileDisplayInfo?

    init(apiService: MessagingAPIServiceProtocol,
         webSocketsService: MessagingWebSocketsServiceProtocol,
         storageProtocol: MessagingStorageServiceProtocol,
         decrypterService: MessagingContentDecrypterService,
         filesService: MessagingFilesServiceProtocol,
         udWalletsService: UDWalletsServiceProtocol) {
        self.apiService = apiService
        self.webSocketsService = webSocketsService
        self.storageService = storageProtocol
        self.decrypterService = decrypterService
        self.filesService = filesService
        udWalletsService.addListener(self)
        
        storageService.markSendingMessagesAsFailed()
        setSceneActivationListener()
    }
    
}

// MARK: - Open methods
extension MessagingService: MessagingServiceProtocol {
    func getUserProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo {
        let domain = try await appContext.dataAggregatorService.getDomainWith(name: domain.name)
        if let cachedProfile = try? storageService.getUserProfileFor(domain: domain) {
            return cachedProfile.displayInfo
        }
        
        let remoteProfile = try await apiService.getUserFor(domain: domain)
        await storageService.saveUserProfile(remoteProfile)
        return remoteProfile.displayInfo
    }
    
    func createUserProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo {
        if let existingUser = try? await getUserProfile(for: domain) {
            return existingUser
        }
        let domain = try await appContext.dataAggregatorService.getDomainWith(name: domain.name)
        let newUser = try await apiService.createUser(for: domain)
        await storageService.saveUserProfile(newUser)
        return newUser.displayInfo
    }
    
    func setCurrentUser(_ userProfile: MessagingChatUserProfileDisplayInfo) {
        Task {
            do {
                self.currentUser = userProfile
                let rrDomain = try await getReverseResolutionDomainItem(for: userProfile.wallet)
                let profile = try storageService.getUserProfileFor(domain: rrDomain)
                
                refreshChatsForProfile(profile, shouldRefreshUserInfo: true)
                refreshChannelsForProfile(profile)
                setupSocketConnection(profile: profile)
            } catch { }
        }
    }
    
    // Chats list
    func getChatsListForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingChatDisplayInfo] {
        let profile = try await getUserProfileWith(wallet: profile.wallet)
        let chats = try await storageService.getChatsFor(profile: profile,
                                                         decrypter: decrypterService)
        
        let chatsDisplayInfo = chats.map { $0.displayInfo }
        return chatsDisplayInfo
    }
    
    func makeChatRequest(_ chat: MessagingChatDisplayInfo, approved: Bool) async throws {
        let profile = try await getUserProfileWith(wallet: chat.thisUserDetails.wallet)
        let chat = try await getMessagingChatFor(displayInfo: chat)
        try await apiService.makeChatRequest(chat, approved: approved, by: profile)
        refreshChatsForProfile(profile, shouldRefreshUserInfo: false)
    }
    
    func leaveGroupChat(_ chat: MessagingChatDisplayInfo) async throws {
        guard case .group = chat.type else { throw MessagingServiceError.attemptToLeaveNotGroupChat }
        
        let profile = try await getUserProfileWith(wallet: chat.thisUserDetails.wallet)
        let chat = try await getMessagingChatFor(displayInfo: chat)

        try await apiService.leaveGroupChat(chat, by: profile)
        storageService.deleteChat(chat, filesService: filesService)
        notifyChatsChanged(wallet: profile.wallet)
    }
    
    func getBlockingStatusForChat(_ chat: MessagingChatDisplayInfo) async throws -> MessagingPrivateChatBlockingStatus {
        let chat = try await getMessagingChatFor(displayInfo: chat)
        
        return try await apiService.getBlockingStatusForChat(chat)
    }
    
    func setUser(in chat: MessagingChatDisplayInfo,
                 blocked: Bool) async throws {
        let profile = try await getUserProfileWith(wallet: chat.thisUserDetails.wallet)
        let chat = try await getMessagingChatFor(displayInfo: chat)

        try await apiService.setUser(in: chat, blocked: blocked, by: profile)
    }
    
    // Messages
    func getMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo,
                            before message: MessagingChatMessageDisplayInfo?,
                            limit: Int) async throws -> [MessagingChatMessageDisplayInfo] {
        var limit = limit
        var message = message
        if let message,
           message.isFirstInChat {
            return [] // There's no messages before this message
        }
        
        let cachedMessages = try await storageService.getMessagesFor(chat: chatDisplayInfo,
                                                                     decrypter: decrypterService,
                                                                     before: message,
                                                                     limit: limit)
        if !cachedMessages.isEmpty {
            if cachedMessages.count == limit ||
                cachedMessages.last?.displayInfo.isFirstInChat == true {
                return cachedMessages.map { $0.displayInfo }
            } else {
                message = cachedMessages.last?.displayInfo
                limit -= cachedMessages.count
            }
        }
        
        let chat = try await getMessagingChatFor(displayInfo: chatDisplayInfo)
        let options: MessagingAPIServiceLoadMessagesOptions
        if let message,
           let chatMessage = await storageService.getMessageWith(id: message.id,
                                                                 in: chatDisplayInfo,
                                                                 decrypter: decrypterService) {
            options = .before(message: chatMessage)
        } else {
            options = .default
        }
        
        let newMessages = try await getAndStoreMessagesForChat(chat, options: options, limit: limit)
        return cachedMessages.map { $0.displayInfo } + newMessages
    }
 
    func getMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo,
                            after message: MessagingChatMessageDisplayInfo,
                            limit: Int) async throws -> [MessagingChatMessageDisplayInfo] {
        let chat = try await getMessagingChatFor(displayInfo: chatDisplayInfo)
        guard let chatMessage = await storageService.getMessageWith(id: message.id,
                                                                    in: chatDisplayInfo,
                                                                    decrypter: decrypterService) else { throw MessagingServiceError.messageNotFound }
        
        return try await getAndStoreMessagesForChat(chat, options: .after(message: chatMessage), limit: limit)
    }

    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChatDisplayInfo) async throws -> MessagingChatMessageDisplayInfo {
        let messagingChat = try await getMessagingChatFor(displayInfo: chat)
        let profile = try await getUserProfileWith(wallet: messagingChat.displayInfo.thisUserDetails.wallet)
        let isMessageEncrypted = await apiService.isMessagesEncryptedIn(chat: messagingChat)
        let newMessageDisplayInfo = MessagingChatMessageDisplayInfo(id: UUID().uuidString,
                                                                    chatId: chat.id,
                                                                    senderType: .thisUser(chat.thisUserDetails),
                                                                    time: Date(),
                                                                    type: messageType,
                                                                    isRead: true,
                                                                    isFirstInChat: false,
                                                                    deliveryState: .sending,
                                                                    isEncrypted: isMessageEncrypted) 
        let message = MessagingChatMessage(displayInfo: newMessageDisplayInfo,
                                           serviceMetadata: nil)
        await storageService.saveMessages([message])
        
        try await setLastMessageAndNotify(newMessageDisplayInfo,
                                          to: messagingChat)
        let newMessage = MessagingChatMessage(displayInfo: newMessageDisplayInfo, serviceMetadata: nil)
        sendMessageToBEAsync(message: newMessage, messageType: messageType, in: messagingChat, by: profile)

        return newMessageDisplayInfo
    }
    
    func sendFirstMessage(_ messageType: MessagingChatMessageDisplayType,
                          to userInfo: MessagingChatUserDisplayInfo,
                          by profile: MessagingChatUserProfileDisplayInfo) async throws -> (MessagingChatDisplayInfo, MessagingChatMessageDisplayInfo) {
        let profile = try await getUserProfileWith(wallet: profile.wallet)
        let (chat, message) = try await apiService.sendFirstMessage(messageType,
                                                                    to: userInfo,
                                                                    by: profile,
                                                                    filesService: filesService)
        
        await storageService.saveChats([chat])
        await storageService.saveMessages([message])
        try? await setLastMessageAndNotify(message.displayInfo, to: chat)
        
        return (chat.displayInfo, message.displayInfo)
    }

    func resendMessage(_ message: MessagingChatMessageDisplayInfo) async throws {
        let chatId = message.chatId
        let messagingChat = try await getMessagingChatWith(chatId: chatId)
        let profile = try await getUserProfileWith(wallet: messagingChat.displayInfo.thisUserDetails.wallet)
        var updatedMessage = message
        updatedMessage.deliveryState = .sending
        let newMessage = MessagingChatMessage(displayInfo: updatedMessage, serviceMetadata: nil)

        replaceCacheMessageAndNotify(.init(displayInfo: message,
                                           serviceMetadata: nil),
                                     with: newMessage)
        sendMessageToBEAsync(message: newMessage, messageType: updatedMessage.type, in: messagingChat, by: profile)
    }
    
    func deleteMessage(_ message: MessagingChatMessageDisplayInfo) {
        storageService.deleteMessage(message)
    }
    
    func markMessage(_ message: MessagingChatMessageDisplayInfo,
                     isRead: Bool,
                     wallet: String) throws {
        try storageService.markMessage(message, isRead: isRead)
        notifyChatsChanged(wallet: wallet)
    }
    
    func decryptedContentURLFor(message: MessagingChatMessageDisplayInfo) async -> URL? {
        let fileName: String
        
        switch message.type {
        case .text, .imageBase64:
            return nil
        case .unknown(let info):
            fileName = info.fileName
        }
        
        if let url = filesService.getDecryptedDataURLFor(fileName: fileName) {
            return url
        }
        
        guard let chat = await storageService.getChatWith(id: message.chatId, decrypter: decrypterService),
              let chatMessage = await storageService.getMessageWith(id: message.id,
                                                                    in: chat.displayInfo,
                                                                    decrypter: decrypterService) else { return nil }
        let wallet = chat.displayInfo.thisUserDetails.wallet
        guard let encryptedDataURL = filesService.getEncryptedDataURLFor(fileName: fileName),
              let encryptedData = try? Data(contentsOf: encryptedDataURL),
              let encryptedContent = String(data: encryptedData, encoding: .utf8),
              let decryptedContent = try? decrypterService.decryptText(encryptedContent,
                                                                       with: chatMessage.serviceMetadata,
                                                                       wallet: wallet),
              let decryptedData = Base64DataTransformer.dataFrom(base64String: decryptedContent) else { return nil }
        
        return try? filesService.saveDecryptedData(decryptedData, fileName: fileName)
    }
    
    // Channels
    func getChannelsForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel] {
        let profile = try await getUserProfileWith(wallet: profile.wallet)
        let channels = try await storageService.getChannelsFor(profile: profile)
        return channels
    }
    
    // TODO: - Break down
    func getFeedFor(channel: MessagingNewsChannel,
                    page: Int,
                    limit: Int) async throws -> [MessagingNewsChannelFeed] {
        let storedFeed = try await storageService.getChannelsFeedFor(channel: channel,
                                                                     page: page,
                                                                     limit: limit)
        
        func checkIfFirstFeedInChannel(_ feed: inout [MessagingNewsChannelFeed]) {
            if feed.count < limit,
               var lastFeed = feed.last {
                lastFeed.isFirstInChannel = true
                feed[feed.count - 1] = lastFeed
            }
        }
        
        func setChannelUpToDate(feed: [MessagingNewsChannelFeed]) async throws {
            guard channel.isCurrentUserSubscribed else { return }
            
            var updatedChannel = channel
            updatedChannel.isUpToDate = true
            if page == 1,
               let latestFeed = feed.first {
                updatedChannel.lastMessage = latestFeed
            }
            try await storageService.replaceChannel(channel, with: updatedChannel)
            notifyChannelsChanged(userId: channel.userId)
        }
        
        if channel.isUpToDate && channel.isCurrentUserSubscribed {
            /// User has opened channel before and there's no unread messages
            if storedFeed.count < limit {
                if storedFeed.last?.isFirstInChannel == true || (storedFeed.isEmpty && page == 1) {
                     return storedFeed
                } else {
                    var loadedFeed = try await apiService.getFeedFor(channel: channel,
                                                                     page: page,
                                                                     limit: limit,
                                                                     isRead: true)
                    checkIfFirstFeedInChannel(&loadedFeed)
                    await storageService.saveChannelsFeed(loadedFeed,
                                                          in: channel)
                    return loadedFeed
                }
            } else {
                return storedFeed
            }
        } else if let latestLocalFeed = storedFeed.first(where: { $0.isRead }) {
            /// User has already opened channel before, but there's some unread messages
            var preLoadPage = 1
            let preLoadLimit = 30
            var preloadedFeed = [MessagingNewsChannelFeed]()
            while true {
                let feed = try await apiService.getFeedFor(channel: channel,
                                                           page: preLoadPage,
                                                           limit: preLoadLimit,
                                                           isRead: false)
                if let i = feed.firstIndex(where: { $0.id == latestLocalFeed.id }) {
                    let missedChunk = feed[0..<i]
                    preloadedFeed.append(contentsOf: missedChunk)
                    break
                } else {
                    preloadedFeed.append(contentsOf: feed)
                    preLoadPage += 1
                }
            }
            
            await storageService.saveChannelsFeed(preloadedFeed,
                                                  in: channel)
            try await setChannelUpToDate(feed: preloadedFeed)
            
            let result = storedFeed + preloadedFeed
            return result
        } else {
            /// User open channel for the first time
            var loadedFeed = try await apiService.getFeedFor(channel: channel,
                                                             page: page,
                                                             limit: limit,
                                                             isRead: true)
            checkIfFirstFeedInChannel(&loadedFeed)
            await storageService.saveChannelsFeed(loadedFeed,
                                                  in: channel)
            try await setChannelUpToDate(feed: loadedFeed)
            
            return loadedFeed
        }
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
        let profile = try await getUserProfileWith(wallet: user.wallet)
        try await apiService.setChannel(channel, subscribed: subscribed, by: profile)
        var channel = channel
        channel.isCurrentUserSubscribed = subscribed
        if subscribed {
            let updatedChannel = await refreshChannelsMetadata([channel], storedChannels: [])
            await storageService.saveChannels(updatedChannel, for: profile)
        } else {
            storageService.deleteChannel(channel)
        }
        
        notifyChannelsChanged(userId: user.id)
    }
    
    // Search
    func searchForUsersWith(searchKey: String) async throws -> [MessagingChatUserDisplayInfo] {
        guard searchKey.isValidAddress() else { return [] }
        
        let wallet = searchKey
        if let userInfo = await loadUserInfoFor(wallet: wallet) {
            return [userInfo]
        }
        
        return [.init(wallet: wallet)]
    }
    
    func searchForChannelsWith(page: Int,
                               limit: Int,
                               searchKey: String,
                               for user: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel] {
        let profile = try await getUserProfileWith(wallet: user.wallet)
        let channels = try await apiService.searchForChannels(page: page, limit: limit, searchKey: searchKey, for: profile)
        
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

// MARK: - Open methods
extension MessagingService: UDWalletsServiceListener {
    func walletsDataUpdated(notification: UDWalletsServiceNotification) {
        Task {
            switch notification {
            case .walletsUpdated, .reverseResolutionDomainChanged:
                return
            case .walletRemoved(let wallet):
                if let rrDomainName = await appContext.dataAggregatorService.getReverseResolutionDomain(for: wallet.address),
                   let rrDomain = try? await appContext.dataAggregatorService.getDomainWith(name: rrDomainName),
                   let profile = try? storageService.getUserProfileFor(domain: rrDomain) {
                    await storageService.clearAllDataOf(profile: profile, filesService: filesService)
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
            
            setCurrentUser(currentUser)
        case .background:
            webSocketsService.disconnectAll()
        case .foregroundInactive, .unattached:
            return
        @unknown default:
            return
        }
    }
}

// MARK: - Chats
private extension MessagingService {
    func refreshChatsForProfile(_ profile: MessagingChatUserProfile, shouldRefreshUserInfo: Bool) {
        Task {
            let startTime = Date()
            do {
                let allLocalChats = try await storageService.getChatsFor(profile: profile,
                                                                         decrypter: decrypterService)
                let localChats = allLocalChats.filter { $0.displayInfo.isApproved}
                let localRequests = allLocalChats.filter { !$0.displayInfo.isApproved}
                
                async let remoteChatsTask = updatedLocalChats(localChats, forProfile: profile, isRequests: false)
                async let remoteRequestsTask = updatedLocalChats(localRequests, forProfile: profile, isRequests: true)
                
                let (remoteChats, remoteRequests) = await (remoteChatsTask, remoteRequestsTask)
                let allRemoteChats = remoteChats + remoteRequests
                
                let updatedChats = await refreshChatsMetadata(remoteChats: allRemoteChats,
                                                              localChats: allLocalChats,
                                                              for: profile)
                await storageService.saveChats(updatedChats)
                
                let updatedStoredChats = try await storageService.getChatsFor(profile: profile,
                                                                              decrypter: decrypterService)
                let chatsDisplayInfo = updatedStoredChats.sortedByLastMessage().map({ $0.displayInfo })
                notifyListenersChangedDataType(.chats(chatsDisplayInfo, profile: profile.displayInfo))
                
                if shouldRefreshUserInfo {
                    refreshUsersInfoFor(profile: profile)
                }
            } catch { }
            Debugger.printTimeSensitiveInfo(topic: .Messaging,
                                            "to refresh chats list for \(profile.wallet)",
                                            startDate: startTime,
                                            timeout: 3)
        }
    }
    
    func updatedLocalChats(_ localChats: [MessagingChat],
                                   forProfile profile: MessagingChatUserProfile,
                                   isRequests: Bool) async -> [MessagingChat] {
        var remoteChats = [MessagingChat]()
        let limit = 30
        var page = 1
        while true {
            do {
                let chatsPage: [MessagingChat]
                if isRequests {
                    chatsPage = try await apiService.getChatRequestsForUser(profile, page: 1, limit: limit)
                } else {
                    chatsPage = try await apiService.getChatsListForUser(profile, page: 1, limit: limit)
                }
                
                remoteChats.append(contentsOf: chatsPage)
                if chatsPage.count < limit {
                    /// Loaded all chats
                    break
                } else if let lastPageChat = chatsPage.last,
                          let localChat = localChats.first(where: { $0.displayInfo.id == lastPageChat.displayInfo.id }),
                          lastPageChat.isUpToDateWith(otherChat: localChat) {
                    /// No changes for other chats
                    break
                } else {
                    page += 1
                }
            } catch {
                break
            }
        }
        
        await storageService.saveChats(remoteChats)
        
        return remoteChats
    }
    
    func refreshChatsMetadata(remoteChats: [MessagingChat],
                              localChats: [MessagingChat],
                              for profile: MessagingChatUserProfile) async -> [MessagingChat] {
        var updatedChats = [MessagingChat]()
        
        await withTaskGroup(of: MessagingChat.self, body: { group in
            for remoteChat in remoteChats {
                group.addTask {
                    if let localChat = localChats.first(where: { $0.displayInfo.id == remoteChat.displayInfo.id }),
                       localChat.isUpToDateWith(otherChat: remoteChat) {
                        return localChat
                    } else {
                        if var lastMessage = try? await self.apiService.getMessagesForChat(remoteChat,
                                                                                           options: .default,
                                                                                           fetchLimit: 1,
                                                                                           for: profile,
                                                                                           filesService: self.filesService).first {
                            
                            var updatedChat = remoteChat
                            updatedChat.displayInfo.lastMessage = lastMessage.displayInfo
                            if let storedMessage = await self.storageService.getMessageWith(id: lastMessage.displayInfo.id,
                                                                                            in: remoteChat.displayInfo,
                                                                                            decrypter: self.decrypterService) {
                                lastMessage.displayInfo.isRead = storedMessage.displayInfo.isRead
                            } else {
                                lastMessage.displayInfo.isRead = false
                            }
                            if !lastMessage.displayInfo.senderType.isThisUser && !lastMessage.displayInfo.isRead {
                                updatedChat.displayInfo.unreadMessagesCount += 1
                            }
                            await self.storageService.saveMessages([lastMessage])
                            return updatedChat
                        } else {
                            return remoteChat
                        }
                    }
                }
            }
            
            for await chat in group {
                updatedChats.append(chat)
            }
        })
        
        return updatedChats
    }
    
    func refreshUsersInfoFor(profile: MessagingChatUserProfile) {
        Task {
            do {
                let chats = try await storageService.getChatsFor(profile: profile,
                                                                 decrypter: decrypterService)
                await withTaskGroup(of: Void.self, body: { group in
                    for chat in chats {
                        group.addTask {
                            if let otherUserInfo = try? await self.loadUserInfoFor(chat: chat) {
                                for info in otherUserInfo {
                                    await self.storageService.saveMessagingUserInfo(info)
                                }
                            }
                            return Void()
                        }
                    }
                    
                    for await _ in group {
                        Void()
                    }
                })
                
                let updatedChats = try await storageService.getChatsFor(profile: profile,
                                                                        decrypter: decrypterService)
                notifyListenersChangedDataType(.chats(updatedChats.map { $0.displayInfo }, profile: profile.displayInfo))
            } catch { }
        }
    }
    
    func loadUserInfoFor(chat: MessagingChat) async throws -> [MessagingChatUserDisplayInfo] {
        switch chat.displayInfo.type {
        case .private(let details):
            let wallet = details.otherUser.wallet
            if let userInfo = await loadUserInfoFor(wallet: wallet) {
                return [userInfo]
            }
            return []
        case .group(let details):
            var infos: [MessagingChatUserDisplayInfo] = []
            let members = details.allMembers.prefix(3) // Only first 3 members will be displayed on the UI
            for member in members {
                if let userInfo = await loadUserInfoFor(wallet: member.wallet) {
                    infos.append(userInfo)
                }
            }
            return infos
        }
    }
    
    func loadUserInfoFor(wallet: String) async -> MessagingChatUserDisplayInfo? {
        if let domain = await appContext.udWalletsService.reverseResolutionDomainName(for: wallet.normalized),
           !domain.isEmpty {
            let pfpInfo = await appContext.udDomainsService.loadPFP(for: domain)
            var pfpURL: URL?
            if let urlString = pfpInfo?.pfpURL,
               let url = URL(string: urlString) {
                pfpURL = url
            }
            return MessagingChatUserDisplayInfo(wallet: wallet,
                                                domainName: domain,
                                                pfpURL: pfpURL)
        }
        
        return nil
    }
}

// MARK: - Messages
private extension MessagingService {
    func getAndStoreMessagesForChat(_ chat: MessagingChat,
                                    options: MessagingAPIServiceLoadMessagesOptions,
                                    limit: Int) async throws -> [MessagingChatMessageDisplayInfo] {
        let startTime = Date()
        let profile = try await getUserProfileWith(wallet: chat.displayInfo.thisUserDetails.wallet)
        var messages = try await apiService.getMessagesForChat(chat,
                                                               options: options,
                                                               fetchLimit: limit,
                                                               for: profile,
                                                               filesService: filesService)
        
        // Check for message is first in the chat when load earlier before
        if case .before(let message) = options {
            if !messages.isEmpty,
               messages.count < limit {
                messages[messages.count - 1].displayInfo.isFirstInChat = true
            } else if messages.isEmpty,
                      let storedMessage = await self.storageService.getMessageWith(id: message.displayInfo.id,
                                                                                   in: chat.displayInfo,
                                                                                   decrypter: self.decrypterService) {
                Task.detached {
                    var updatedMessage = storedMessage
                    updatedMessage.displayInfo.isFirstInChat = true
                    self.replaceCacheMessageAndNotify(storedMessage,
                                                      with: updatedMessage)
                }
            }
        }
        Debugger.printTimeSensitiveInfo(topic: .Messaging,
                                        "to fetch \(messages.count) messages",
                                        startDate: startTime,
                                        timeout: 3)
        await storageService.saveMessages(messages)
        return messages.map { $0.displayInfo }
    }
    
    func sendMessageToBEAsync(message: MessagingChatMessage,
                              messageType: MessagingChatMessageDisplayType,
                              in chat: MessagingChat,
                              by user: MessagingChatUserProfile) {
        Task {
            do {
                let sentMessage = try await apiService.sendMessage(messageType,
                                                                   in: chat,
                                                                   by: user,
                                                                   filesService: filesService)
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
        }
    }
}

// MARK: - Channels
private extension MessagingService {
    func refreshChannelsForProfile(_ profile: MessagingChatUserProfile) {
        Task {
            let startTime = Date()
            do {
                let storedChannels = try await storageService.getChannelsFor(profile: profile)

                async let channelsTask = Utilities.catchingFailureAsyncTask(asyncCatching: {
                    try await apiService.getSubscribedChannelsForUser(profile)
                }, defaultValue: [])
                async let spamChannelsTask = Utilities.catchingFailureAsyncTask(asyncCatching: {
                    try await apiService.getSpamChannelsForUser(profile)
                }, defaultValue: [])
                
                let (channels, spamChannels) = await (channelsTask, spamChannelsTask)
                let allChannels = channels + spamChannels
                
                let updatedChats = await refreshChannelsMetadata(allChannels, storedChannels: storedChannels).sortedByLastMessage()
                
                await storageService.saveChannels(updatedChats, for: profile)
                
                let updatedStoredChannels = try await storageService.getChannelsFor(profile: profile)
                notifyListenersChangedDataType(.channels(updatedStoredChannels, profile: profile.displayInfo))
            } catch { }
            Debugger.printTimeSensitiveInfo(topic: .Messaging,
                                            "to refresh channels list for \(profile.wallet)",
                                            startDate: startTime,
                                            timeout: 3)
        }
    }
    
    func refreshChannelsMetadata(_ channels: [MessagingNewsChannel],
                                 storedChannels: [MessagingNewsChannel]) async -> [MessagingNewsChannel] {
        var updatedChannels = [MessagingNewsChannel]()
        
        await withTaskGroup(of: MessagingNewsChannel.self, body: { group in
            for channel in channels {
                group.addTask {
                    if var lastMessage = try? await self.apiService.getFeedFor(channel: channel,
                                                                               page: 1,
                                                                               limit: 1,
                                                                               isRead: false).first {
                        var updatedChannel = channel
                        if let storedChannel = storedChannels.first(where: { $0.id == channel.id }),
                           let storedLastMessage = storedChannel.lastMessage,
                           storedLastMessage.id == lastMessage.id {
                            updatedChannel.isUpToDate = true
                            lastMessage.isRead = storedLastMessage.isRead
                        } else {
                            updatedChannel.isUpToDate = false
                            lastMessage.isRead = true
                            await self.storageService.saveChannelsFeed([lastMessage],
                                                                       in: channel)
                        }
                        updatedChannel.lastMessage = lastMessage
                        return updatedChannel
                    } else {
                        return channel
                    }
                }
            }
            
            for await channel in group {
                updatedChannels.append(channel)
            }
        })
        
        return updatedChannels
    }
}

// MARK: - Private methods
private extension MessagingService {
    func getReverseResolutionDomainItem(for wallet: String) async throws -> DomainItem {
        guard let domainName = await appContext.dataAggregatorService.getReverseResolutionDomain(for: wallet.normalized) else {
            throw MessagingServiceError.noRRDomainForProfile
        }
        return try await appContext.dataAggregatorService.getDomainWith(name: domainName)
    }
    
    func getDomainEthWalletAddress(_ domain: DomainDisplayInfo) throws -> String {
        guard let ethAddress = domain.getETHAddress() else { throw MessagingServiceError.domainWithoutWallet }
        return ethAddress
    }
    
    func getMessagingChatFor(displayInfo: MessagingChatDisplayInfo) async throws -> MessagingChat {
        try await getMessagingChatWith(chatId: displayInfo.id)
    }
    
    func getMessagingChatWith(chatId: String) async throws -> MessagingChat {
        guard let chat = await storageService.getChatWith(id: chatId,
                                                          decrypter: decrypterService) else { throw MessagingServiceError.chatNotFound }
        
        return chat
    }
  
    func getUserProfileWith(wallet: String) async throws -> MessagingChatUserProfile {
        let rrDomain = try await getReverseResolutionDomainItem(for: wallet)
        return try storageService.getUserProfileFor(domain: rrDomain)
    }
    
    func replaceCacheMessageAndNotify(_ messageToReplace: MessagingChatMessage,
                                      with newMessage: MessagingChatMessage) {
        Task {
            try? await storageService.replaceMessage(messageToReplace, with: newMessage)
            notifyListenersChangedDataType(.messageUpdated(messageToReplace.displayInfo, newMessage: newMessage.displayInfo))
        }
    }
    
    func setupSocketConnection(profile: MessagingChatUserProfile) {
        Task {
            do {
                webSocketsService.disconnectAll()
                try webSocketsService.subscribeFor(profile: profile,
                                                   eventCallback: { [weak self] event in
                    self?.handleWebSocketEvent(event)
                })
            }
        }
    }
    
    func handleWebSocketEvent(_ event: MessagingWebSocketEvent) {
        Task {
            func addNewChatMessages(_ chatMessages: [MessagingChatMessage]) async {
                guard !chatMessages.isEmpty else { return }
                
                await storageService.saveMessages(chatMessages)
                for chatMessage in chatMessages {
                    let chatId = chatMessage.displayInfo.chatId
                    
                    notifyListenersChangedDataType(.messagesAdded([chatMessage.displayInfo],
                                                                  chatId: chatId))
                    refreshChatsInSameDomain(as: chatId)
                }
            }
            
            do {
                switch event {
                case .channelNewFeed(let feed, let channelAddress), .channelSpamFeed(let feed, let channelAddress):
                    let channels = try await storageService.getChannelsWith(address: channelAddress)
                    
                    for var channel in channels {
                        let profile = try storageService.getUserProfileWith(userId: channel.userId)
                        await storageService.saveChannelsFeed([feed], in: channel)
                        channel.lastMessage = feed
                        channel.isUpToDate = false
                        await storageService.saveChannels([channel], for: profile)
                        notifyListenersChangedDataType(.channelFeedAdded(feed, channelId: channel.id))
                        notifyChannelsChanged(userId: profile.id)
                    }
                case .groupChatReceivedMessage(let message):
                    let chatMessages = try await convertMessagingWebSocketGroupMessageEntityToMessage(message)
                    await addNewChatMessages(chatMessages)
                case .chatReceivedMessage(let message):
                    let chatMessage = try await convertMessagingWebSocketMessageEntityToMessage(message)
                    await addNewChatMessages([chatMessage])
                }
            } catch { }
        }
    }
    
    func refreshChatsInSameDomain(as chatId: String) {
        Task {
            do {
                let chat = try await getMessagingChatWith(chatId: chatId)
                let profile = try await getUserProfileWith(wallet: chat.displayInfo.thisUserDetails.wallet)
                refreshChatsForProfile(profile, shouldRefreshUserInfo: false)
            } catch { }
        }
    }
    
    func notifyChannelsChanged(userId: String) {
        Task {
            do {
                let profile = try storageService.getUserProfileWith(userId: userId)
                let channels = try await storageService.getChannelsFor(profile: profile)
                notifyListenersChangedDataType(.channels(channels, profile: profile.displayInfo))
            } catch { }
        }
    }
    
    func notifyChatsChanged(wallet: String) {
        Task {
            do {
                let profile = try await getUserProfileWith(wallet: wallet)
                let chats = try await storageService.getChatsFor(profile: profile,
                                                                 decrypter: decrypterService)
                let displayInfo = chats.map { $0.displayInfo }
                notifyListenersChangedDataType(.chats(displayInfo, profile: profile.displayInfo))
            } catch { }
        }
    }
    
    func notifyListenersChangedDataType(_ messagingDataType: MessagingDataType) {
        listenerHolders.forEach { holder in
            holder.listener?.messagingDataTypeDidUpdated(messagingDataType)
        }
    }
    
    func setLastMessageAndNotify(_ lastMessage: MessagingChatMessageDisplayInfo,
                                 to chat: MessagingChat) async throws {
        var updatedChat = chat
        updatedChat.displayInfo.lastMessage = lastMessage
        updatedChat.displayInfo.lastMessageTime = lastMessage.time
        try await storageService.replaceChat(chat, with: updatedChat)
        notifyChatsChanged(wallet: chat.displayInfo.thisUserDetails.wallet)
    }
    
    func convertMessagingWebSocketMessageEntityToMessage(_ messageEntity: MessagingWebSocketMessageEntity) async throws -> MessagingChatMessage {
        let profile = try await getUserProfileWith(wallet: messageEntity.receiverWallet)
        let chats = try await storageService.getChatsFor(profile: profile,
                                                         decrypter: decrypterService)
        guard let chat = chats.first(where: { chat in
                  switch chat.displayInfo.type {
                  case .private(let details):
                      return details.otherUser.wallet == messageEntity.senderWallet
                  case .group:
                      return false
                  }
              }) else { throw MessagingServiceError.chatNotFound }
        guard let message = messageEntity.transformToMessageBlock(messageEntity, chat, filesService) else { throw MessagingServiceError.failedToConvertWebsocketMessage }
        return message
    }
    
    func convertMessagingWebSocketGroupMessageEntityToMessage(_ messageEntity: MessagingWebSocketGroupMessageEntity) async throws -> [MessagingChatMessage] {
        let chats = await storageService.getChatsWithIdContaining(messageEntity.chatId,
                                                                  decrypter: decrypterService)
        return chats.compactMap({ messageEntity.transformToMessageBlock(messageEntity, $0, filesService) })
    }
    
    func setSceneActivationListener() {
        Task { @MainActor in
            SceneDelegate.shared?.addListener(self)
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
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
