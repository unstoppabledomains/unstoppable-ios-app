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
        
    private var walletsToChatsCache: [String : [MessagingChat]] = [:]
    private var chatToMessagesCache: [String : [MessagingChatMessage]] = [:]
    private var walletToChannelsCache: [String : [MessagingNewsChannel]] = [:]
    private var listenerHolders: [MessagingListenerHolder] = []

    init(apiService: MessagingAPIServiceProtocol,
         webSocketsService: MessagingWebSocketsServiceProtocol,
         storageProtocol: MessagingStorageServiceProtocol,
         decrypterService: MessagingContentDecrypterService) {
        self.apiService = apiService
        self.webSocketsService = webSocketsService
        self.storageService = storageProtocol
        self.decrypterService = decrypterService
    }
    
}

// MARK: - Open methods
extension MessagingService: MessagingServiceProtocol {
    func refreshChatsForDomain(_ domain: DomainDisplayInfo) {
        Task {
            setupSocketConnection(domain: domain)

            do {
                let wallet = try getDomainEthWalletAddress(domain)

                let allLocalChats = try await storageService.getChatsFor(decrypter: decrypterService, wallet: wallet)
                let localChats = allLocalChats.filter { $0.displayInfo.isApproved}
                let localRequests = allLocalChats.filter { !$0.displayInfo.isApproved}
                
                async let remoteChatsTask = updatedLocalChats(localChats, forWallet: wallet, isRequests: false)
                async let remoteRequestsTask = updatedLocalChats(localRequests, forWallet: wallet, isRequests: true)
                
                let (remoteChats, remoteRequests) = try await (remoteChatsTask, remoteRequestsTask)
                let allRemoteChats = remoteChats + remoteRequests
                
                let updatedChats = await refreshChatsMetadata(remoteChats: allRemoteChats, localChats: allLocalChats)
                await storageService.saveChats(updatedChats)
                
                let chatsDisplayInfo = updatedChats.map { $0.displayInfo }.sorted(by: { $0.lastMessageTime > $1.lastMessageTime})
                notifyListenersChangedDataType(.chats(chatsDisplayInfo, wallet: domain.ownerWallet!))
                
                refreshUsersInfoFor(domain: domain)
            } catch {
                // TODO: - Handle error
            }
        }
    }
    
    private func updatedLocalChats(_ localChats: [MessagingChat],
                                   forWallet wallet: String,
                                   isRequests: Bool) async throws -> [MessagingChat] {
        var remoteChats = [MessagingChat]()
        let limit = 30
        var page = 1
        while true {
            let chatsPage: [MessagingChat]
            if isRequests {
                chatsPage = try await apiService.getChatRequestsForWallet(wallet, page: 1, limit: limit)
            } else {
                chatsPage = try await apiService.getChatsListForWallet(wallet, page: 1, limit: limit)
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
    
    private func refreshChatsMetadata(remoteChats: [MessagingChat], localChats: [MessagingChat]) async -> [MessagingChat] {
        var updatedChats = [MessagingChat]()
        
        await withTaskGroup(of: MessagingChat.self, body: { group in
            for remoteChat in remoteChats {
                group.addTask {
                    if let localChat = localChats.first(where: { $0.displayInfo.id == remoteChat.displayInfo.id }),
                       localChat.isUpToDateWith(otherChat: remoteChat) {
                        return localChat
                    } else {
                        if let lastMessage = try? await self.apiService.getMessagesForChat(remoteChat,
                                                                                           options: .default,
                                                                                           fetchLimit: 1).first {
                            await self.storageService.saveMessages([lastMessage])
                            var updatedChat = remoteChat
                            updatedChat.displayInfo.lastMessage = lastMessage.displayInfo
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
    
    private func refreshUsersInfoFor(domain: DomainDisplayInfo) {
        Task {
            do {
                let wallet = try getDomainEthWalletAddress(domain)
                let chats = try await storageService.getChatsFor(decrypter: decrypterService,
                                                                 wallet: wallet)
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
                
                let updatedChats = try await storageService.getChatsFor(decrypter: decrypterService,
                                                                 wallet: wallet)
                notifyListenersChangedDataType(.chats(updatedChats.map { $0.displayInfo }, wallet: domain.ownerWallet!))
            } catch { }
        }
    }
    
    private func loadUserInfoFor(chat: MessagingChat) async throws -> MessagingChatUserDisplayInfo? {
        switch chat.displayInfo.type {
        case .private(let details):
            let wallet = details.otherUser.wallet
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
        case .group(let details):
            return nil // <GROUP_CHAT> Not supported for now
        }
    }
    
    // Chats list
    func getChatsListForDomain(_ domain: DomainDisplayInfo) async throws -> [MessagingChatDisplayInfo] {
        let wallet = try getDomainEthWalletAddress(domain)
        let chats = try await storageService.getChatsFor(decrypter: decrypterService, wallet: wallet)
        
        let chatsDisplayInfo = chats.map { $0.displayInfo }
        return chatsDisplayInfo
    }
    
    // Messages
    // Fetch limit is 30 max
    func getCachedMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo) async throws -> [MessagingChatMessageDisplayInfo] {
        try await storageService.getMessagesFor(chat: chatDisplayInfo,
                                                decrypter: decrypterService).map({ $0.displayInfo })
    }
    
    func getMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo,
                            before message: MessagingChatMessageDisplayInfo?,
                            limit: Int) async throws -> [MessagingChatMessageDisplayInfo] {
        if let message,
           message.isFirstInChat {
            return [] // There's no messages before this message
        }
        
        let cachedMessages = try await storageService.getMessagesFor(chat: chatDisplayInfo,
                                                                     decrypter: decrypterService,
                                                                     before: message,
                                                                     limit: limit)
        if !cachedMessages.isEmpty {
            return cachedMessages.map { $0.displayInfo }
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
        
        return try await getAndStoreMessagesForChat(chat, options: options, limit: limit)
    }
 
    func getMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo,
                            after message: MessagingChatMessageDisplayInfo,
                            limit: Int) async throws -> [MessagingChatMessageDisplayInfo] {
        let cachedMessages = try await storageService.getMessagesFor(chat: chatDisplayInfo,
                                                                     decrypter: decrypterService,
                                                                     after: message,
                                                                     limit: limit)
        if !cachedMessages.isEmpty {
            return cachedMessages.map { $0.displayInfo }
        }
        
        let chat = try await getMessagingChatFor(displayInfo: chatDisplayInfo)
        guard let chatMessage = await storageService.getMessageWith(id: message.id,
                                                                    in: chatDisplayInfo,
                                                                    decrypter: decrypterService) else { throw MessagingServiceError.messageNotFound }
        
        return try await getAndStoreMessagesForChat(chat, options: .after(message: chatMessage), limit: limit)
    }
    
    
    private func getAndStoreMessagesForChat(_ chat: MessagingChat,
                                            options: MessagingAPIServiceLoadMessagesOptions,
                                            limit: Int) async throws -> [MessagingChatMessageDisplayInfo] {
        var messages = try await apiService.getMessagesForChat(chat,
                                                               options: options,
                                                               fetchLimit: limit)
        
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
                    try? await self.storageService.replaceMessage(storedMessage,
                                                                  with: updatedMessage)
                    self.notifyListenersChangedDataType(.messages([updatedMessage.displayInfo],
                                                                  chatId: chat.displayInfo.id))
                }
            }
        }
        
        await storageService.saveMessages(messages)
        return messages.map { $0.displayInfo }
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChatDisplayInfo) async throws -> MessagingChatMessageDisplayInfo {
        let cacheId = chat.id
        let messagingChat = try await getMessagingChatFor(displayInfo: chat)
        var messages = chatToMessagesCache[cacheId] ?? []
        
        let newMessageDisplayInfo = MessagingChatMessageDisplayInfo(id: UUID().uuidString,
                                                                    chatId: chat.id,
                                                                    senderType: .thisUser(chat.thisUserDetails),
                                                                    time: Date(),
                                                                    type: messageType,
                                                                    isRead: false,
                                                                    isFirstInChat: false,
                                                                    deliveryState: .sending)
        setLastMessage(newMessageDisplayInfo,
                       to: chat)
        notifyChatsChanged(wallet: chat.thisUserDetails.wallet)
        let newMessage = MessagingChatMessage(displayInfo: newMessageDisplayInfo, serviceMetadata: nil)
        messages.append(newMessage)
        chatToMessagesCache[cacheId] = messages
        sendMessageToBE(message: newMessage, messageType: messageType, in: messagingChat)
        notifyMessagesChanges(chatId: cacheId)

        return newMessageDisplayInfo
    }
    
    func makeChatRequest(_ chat: MessagingChatDisplayInfo, approved: Bool) async throws {
        let chat = try await getMessagingChatFor(displayInfo: chat)
        try await apiService.makeChatRequest(chat, approved: approved)
        // TODO: - Reload chats list?
    }
    
    func resendMessage(_ message: MessagingChatMessageDisplayInfo) async throws {
        let cacheId = message.chatId
        let messagingChat = try await getMessagingChatWith(chatId: cacheId)
        var updatedMessage = message
        updatedMessage.deliveryState = .sending
        let newMessage = MessagingChatMessage(displayInfo: updatedMessage, serviceMetadata: nil)

        replaceCacheMessage(.init(displayInfo: message,
                                  serviceMetadata: nil),
                            with: newMessage,
                            cacheId: cacheId)
        notifyMessagesChanges(chatId: cacheId)
        sendMessageToBE(message: newMessage, messageType: updatedMessage.type, in: messagingChat)
    }
    
    func deleteMessage(_ message: MessagingChatMessageDisplayInfo) {
        let cacheId = message.chatId
        var messages = chatToMessagesCache[cacheId] ?? []
        if let i = messages.firstIndex(where: { $0.displayInfo.id == message.id }) {
            messages.remove(at: i)
            chatToMessagesCache[cacheId] = messages
            notifyMessagesChanges(chatId: cacheId)
        }
    }
    
    // Channels
    func refreshChannelsForDomain(_ domain: DomainDisplayInfo) {
        Task {
            setupSocketConnection(domain: domain)
            
            do {
                let wallet = try getDomainEthWalletAddress(domain)
                let channels = try await apiService.getSubscribedChannelsFor(wallet: wallet)
                let updatedChats = await refreshChannelsMetadata(channels).sortedByLastMessage()
                
                await storageService.saveChannels(updatedChats, for: wallet)
                notifyListenersChangedDataType(.channels(updatedChats, wallet: domain.ownerWallet!))
            }
        }
    }
    
    private func refreshChannelsMetadata(_ channels: [MessagingNewsChannel]) async -> [MessagingNewsChannel] {
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
    
    func getSubscribedChannelsFor(domain: DomainDisplayInfo) async throws -> [MessagingNewsChannel] {
        let wallet = try getDomainEthWalletAddress(domain)
        let channels = try await storageService.getChannelsFor(wallet: wallet).sortedByLastMessage()
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

// MARK: - Private methods
private extension MessagingService {
    func getDomainEthWalletAddress(_ domain: DomainDisplayInfo) throws -> String {
        guard let walletAddress = domain.ownerWallet,
              let wallet = appContext.udWalletsService.find(by: walletAddress),
              let ethAddress = wallet.ethWallet?.address else { throw MessagingServiceError.domainWithoutWallet }
        
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
    
    func appendChatsToCache(_ chats: [MessagingChat], wallet: HexAddress) {
        var currentChats = walletsToChatsCache[wallet] ?? []
        for chat in chats {
            if let i = currentChats.firstIndex(where: { $0.displayInfo.id == chat.displayInfo.id }) {
                currentChats.remove(at: i)
            }
        }
        currentChats.append(contentsOf: chats)
        walletsToChatsCache[wallet] = currentChats
    }
    
    func sendMessageToBE(message: MessagingChatMessage,
                         messageType: MessagingChatMessageDisplayType,
                         in chat: MessagingChat) {
        Task {
            let chatId = chat.displayInfo.id
            do {
                let sentMessage = try await apiService.sendMessage(messageType, in: chat)
                replaceCacheMessage(message,
                                    with: sentMessage,
                                    cacheId: chatId)
            } catch {
                var failedMessage = message
                failedMessage.displayInfo.deliveryState = .failedToSend
                replaceCacheMessage(message,
                                    with: failedMessage,
                                    cacheId: chatId)
            }
            
            notifyMessagesChanges(chatId: chatId)
        }
    }
    
    func replaceCacheMessage(_ messageToReplace: MessagingChatMessage,
                             with newMessage: MessagingChatMessage,
                             cacheId: String) {
        var messages = chatToMessagesCache[cacheId] ?? []
        if let i = messages.firstIndex(where: { $0.displayInfo.id == messageToReplace.displayInfo.id }) {
            messages[i] = newMessage
            chatToMessagesCache[cacheId] = messages
        }
    }
    
    func setupSocketConnection(domain: DomainDisplayInfo) {
        Task {
            do {
                let domain = try await appContext.dataAggregatorService.getDomainWith(name: domain.name)
                try webSocketsService.subscribeFor(domain: domain,
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
        case .chatReceivedMessage(let messages):
            let chatMessages = messages.compactMap({ convertMessagingWebSocketMessageEntityToMessage($0) })
            
            for chatMessage in chatMessages {
                var messages = chatToMessagesCache[chatMessage.displayInfo.chatId] ?? []
                messages.append(chatMessage)
                chatToMessagesCache[chatMessage.displayInfo.chatId] = messages
            }
            
            let chatIds = Set(chatMessages.map({ $0.displayInfo.chatId }))
            for chatId in chatIds {
                notifyMessagesChanges(chatId: chatId)
            }
            return
        }
    }
    
    func notifyMessagesChanges(chatId: String) {
        let messages = (chatToMessagesCache[chatId] ?? []).map({ $0.displayInfo })
        notifyListenersChangedDataType(.messages(messages, chatId: chatId))
    }
    
    func notifyChatsChanged(wallet: String) {
        let chats = (walletsToChatsCache[wallet] ?? []).map { $0.displayInfo }
        notifyListenersChangedDataType(.chats(chats, wallet: wallet))
    }
    
    func notifyListenersChangedDataType(_ messagingDataType: MessagingDataType) {
        listenerHolders.forEach { holder in
            holder.listener?.messagingDataTypeDidUpdated(messagingDataType)
        }
    }
    
    func setLastMessage(_ lastMessage: MessagingChatMessageDisplayInfo,
                        to chat: MessagingChatDisplayInfo) {
        let wallet = chat.thisUserDetails.wallet
        var chats = walletsToChatsCache[wallet] ?? []
        if let i = chats.firstIndex(where: { $0.displayInfo.id == chat.id }) {
            chats[i].displayInfo.lastMessage = lastMessage
            walletsToChatsCache[wallet] = chats
        }
    }
    
    func convertMessagingWebSocketMessageEntityToMessage(_ messageEntity: MessagingWebSocketMessageEntity) -> MessagingChatMessage? {
        guard let chats: [MessagingChat] = walletsToChatsCache[messageEntity.receiverWallet],
              let chat = chats.first(where: { chat in
                  switch chat.displayInfo.type {
                  case .private(let details):
                      return details.otherUser.wallet == messageEntity.senderWallet
                  case .group:
                      return false
                  }
              }) else { return nil }
        let messageDisplayInfo = MessagingChatMessageDisplayInfo(id: messageEntity.id,
                                                                 chatId: chat.displayInfo.id,
                                                                 senderType: .otherUser(messageEntity.senderDisplayInfo),
                                                                 time: messageEntity.time,
                                                                 type: messageEntity.type,
                                                                 isRead: false,
                                                                 isFirstInChat: false,
                                                                 deliveryState: .delivered)
        let message = MessagingChatMessage(displayInfo: messageDisplayInfo,
                                           serviceMetadata: nil)
        return message
    }
}

// MARK: - Open methods
extension MessagingService {
    enum MessagingServiceError: Error {
        case domainWithoutWallet
        case chatNotFound
        case messageNotFound
    }
}
