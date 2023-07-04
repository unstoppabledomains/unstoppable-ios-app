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
        
    private var listenerHolders: [MessagingListenerHolder] = []

    init(apiService: MessagingAPIServiceProtocol,
         webSocketsService: MessagingWebSocketsServiceProtocol,
         storageProtocol: MessagingStorageServiceProtocol,
         decrypterService: MessagingContentDecrypterService) {
        self.apiService = apiService
        self.webSocketsService = webSocketsService
        self.storageService = storageProtocol
        self.decrypterService = decrypterService
        
        storageService.markSendingMessagesAsFailed()
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
        // TODO: - Reload chats list?
    }
    
    // Messages
    func getCachedMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo) async throws -> [MessagingChatMessageDisplayInfo] {
        try await storageService.getMessagesFor(chat: chatDisplayInfo,
                                                decrypter: decrypterService).map({ $0.displayInfo })
    }
    
    // Fetch limit is 30 max
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
            if cachedMessages.count == limit {
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
        let newMessageDisplayInfo = MessagingChatMessageDisplayInfo(id: UUID().uuidString,
                                                                    chatId: chat.id,
                                                                    senderType: .thisUser(chat.thisUserDetails),
                                                                    time: Date(),
                                                                    type: messageType,
                                                                    isRead: true,
                                                                    isFirstInChat: false,
                                                                    deliveryState: .sending)
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
                                                                    by: profile)
        
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
    
    func deleteMessage(_ message: MessagingChatMessageDisplayInfo) throws {
        try storageService.deleteMessage(message)
    }
    
    func markMessage(_ message: MessagingChatMessageDisplayInfo,
                     isRead: Bool,
                     wallet: String) throws {
        try storageService.markMessage(message, isRead: isRead)
        notifyChatsChanged(wallet: wallet)
    }
    
    // Channels
    func getSubscribedChannelsForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel] {
        let profile = try await getUserProfileWith(wallet: profile.wallet)
        let channels = try await storageService.getChannelsFor(profile: profile)
        return channels
    }
    
    func getNotificationsInboxFor(domain: DomainDisplayInfo,
                                  page: Int,
                                  limit: Int,
                                  isSpam: Bool) async throws -> [MessagingNewsChannelFeed] {
        let wallet = try getDomainEthWalletAddress(domain)
        let feed = try await apiService.getNotificationsInboxFor(wallet: wallet,
                                                                 page: page,
                                                                 limit: limit,
                                                                 isSpam: isSpam)
        
        
        return feed
    }
    
    // Search
    func searchForUsersWith(searchKey: String) async throws -> [MessagingChatUserDisplayInfo] {
        guard searchKey.isValidAddress() else { return [] }
        
        if let userInfo = await loadUserInfoFor(wallet: searchKey) {
            return [userInfo]
        }
        
        return []
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

// MARK: - Chats
private extension MessagingService {
    func refreshChatsForProfile(_ profile: MessagingChatUserProfile, shouldRefreshUserInfo: Bool) {
        Task {
            do {
                let allLocalChats = try await storageService.getChatsFor(profile: profile,
                                                                         decrypter: decrypterService)
                let localChats = allLocalChats.filter { $0.displayInfo.isApproved}
                let localRequests = allLocalChats.filter { !$0.displayInfo.isApproved}
                
                async let remoteChatsTask = updatedLocalChats(localChats, forProfile: profile, isRequests: false)
                async let remoteRequestsTask = updatedLocalChats(localRequests, forProfile: profile, isRequests: true)
                
                let (remoteChats, remoteRequests) = try await (remoteChatsTask, remoteRequestsTask)
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
            } catch {
                // TODO: - Handle error
            }
        }
    }
    
    func updatedLocalChats(_ localChats: [MessagingChat],
                                   forProfile profile: MessagingChatUserProfile,
                                   isRequests: Bool) async throws -> [MessagingChat] {
        var remoteChats = [MessagingChat]()
        let limit = 30
        var page = 1
        while true {
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
                                                                                           for: profile).first {
                            
                            var updatedChat = remoteChat
                            updatedChat.displayInfo.lastMessage = lastMessage.displayInfo
                            if let storedMessage = await self.storageService.getMessageWith(id: lastMessage.displayInfo.id,
                                                                                            in: remoteChat.displayInfo,
                                                                                            decrypter: self.decrypterService) {
                                lastMessage.displayInfo.isRead = storedMessage.displayInfo.isRead
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
                                await self.storageService.saveMessagingUserInfo(otherUserInfo)
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
    
    func loadUserInfoFor(chat: MessagingChat) async throws -> MessagingChatUserDisplayInfo? {
        switch chat.displayInfo.type {
        case .private(let details):
            let wallet = details.otherUser.wallet
            return await loadUserInfoFor(wallet: wallet)
        case .group(let details):
            return nil // <GROUP_CHAT> Not supported for now
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
        let profile = try await getUserProfileWith(wallet: chat.displayInfo.thisUserDetails.wallet)
        var messages = try await apiService.getMessagesForChat(chat,
                                                               options: options,
                                                               fetchLimit: limit,
                                                               for: profile)
        
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
                                                                   by: user)
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
            do {
                let channels = try await apiService.getSubscribedChannelsForUser(profile)
                let updatedChats = await refreshChannelsMetadata(channels).sortedByLastMessage()
                
                await storageService.saveChannels(updatedChats, for: profile)
                notifyListenersChangedDataType(.channels(updatedChats, profile: profile.displayInfo))
            }
        }
    }
    
    func refreshChannelsMetadata(_ channels: [MessagingNewsChannel]) async -> [MessagingNewsChannel] {
        var updatedChannels = [MessagingNewsChannel]()
        
        await withTaskGroup(of: MessagingNewsChannel.self, body: { group in
            for channel in channels {
                group.addTask {
                    if let lastMessage = try? await self.apiService.getFeedFor(channel: channel,
                                                                               page: 1,
                                                                               limit: 1).first {
                        await self.storageService.saveChannelsFeed([lastMessage],
                                                                   in: channel)
                        var updatedChannel = channel
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
                try webSocketsService.subscribeFor(profile: profile,
                                                   eventCallback: { [weak self] event in
                    self?.handleWebSocketEvent(event)
                })
            }
        }
    }
    
    func handleWebSocketEvent(_ event: MessagingWebSocketEvent) {
        switch event {
        case .userFeeds(let feeds):
            return
        case .userSpamFeeds(let feeds):
            return
        case .chatGroups:
            return
        case .chatReceivedMessage(let message):
            Task {
                do {
                    let chatMessage = try await convertMessagingWebSocketMessageEntityToMessage(message)
                    
                    await storageService.saveMessages([chatMessage])
                    let chatId = chatMessage.displayInfo.chatId
                    
                    notifyListenersChangedDataType(.messagesAdded([chatMessage.displayInfo],
                                                                  chatId: chatId))
                    refreshChatsInSameDomain(as: chatId)
                } catch { }
            }
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
        let message = messageEntity.transformToMessageBlock(messageEntity, chat)
        return message
    }
}

// MARK: - Open methods
extension MessagingService {
    enum MessagingServiceError: String, LocalizedError {
        case domainWithoutWallet
        case chatNotFound
        case messageNotFound
        case noRRDomainForProfile
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
