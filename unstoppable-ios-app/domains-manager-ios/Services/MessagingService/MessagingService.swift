//
//  MessagingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

final class MessagingService {

    let apiService: MessagingAPIServiceProtocol
    let webSocketsService: MessagingWebSocketsServiceProtocol
    let storageProtocol: MessagingStorageServiceProtocol
        
    private var walletsToChatsCache: [String : [MessagingChat]] = [:]
    private var walletsToChatRequestsCache: [String : [MessagingChat]] = [:]
    private var chatToMessagesCache: [String : [MessagingChatMessage]] = [:]
    private var walletToChannelsCache: [String : [MessagingNewsChannel]] = [:]
    private var listenerHolders: [MessagingListenerHolder] = []

    init(apiService: MessagingAPIServiceProtocol,
         webSocketsService: MessagingWebSocketsServiceProtocol,
         storageProtocol: MessagingStorageServiceProtocol) {
        self.apiService = apiService
        self.webSocketsService = webSocketsService
        self.storageProtocol = storageProtocol
    }
    
}

// MARK: - Open methods
extension MessagingService: MessagingServiceProtocol {
    // Chats list
    func getChatsListForDomain(_ domain: DomainDisplayInfo,
                               page: Int, // Starting from 1
                               limit: Int) async throws -> [MessagingChatDisplayInfo] {
        guard let wallet = domain.ownerWallet else { throw MessagingServiceError.domainWithoutWallet }
        let cacheId = wallet
        if let cache = walletsToChatsCache[cacheId] {
            return cache.map { $0.displayInfo }
        }
        let chats = try await apiService.getChatsListForWallet(wallet, page: page, limit: limit)
        walletsToChatsCache[cacheId] = chats
        setupSocketConnection(domain: domain)
        
        let chatsDisplayInfo = chats.map { $0.displayInfo }
        notifyListenersChangedDataType(.chats(chatsDisplayInfo, isRequests: false, wallet: wallet))
        return chatsDisplayInfo
    }
    
    func getChatRequestsForDomain(_ domain: DomainDisplayInfo,
                                  page: Int,
                                  limit: Int) async throws -> [MessagingChatDisplayInfo] {
        guard let wallet = domain.ownerWallet else { throw MessagingServiceError.domainWithoutWallet }
        let cacheId = wallet
        if let cache = walletsToChatRequestsCache[cacheId] {
            return cache.map { $0.displayInfo }
        }
        let chats = try await apiService.getChatRequestsForWallet(wallet, page: page, limit: limit)
        walletsToChatRequestsCache[cacheId] = chats
        
        let chatsDisplayInfo = chats.map { $0.displayInfo }
        notifyListenersChangedDataType(.chats(chatsDisplayInfo, isRequests: true, wallet: wallet))
        return chatsDisplayInfo
    }

    // Messages
    // Fetch limit is 30 max
    func getMessagesForChat(_ chat: MessagingChatDisplayInfo,
                            fetchLimit: Int) async throws -> [MessagingChatMessageDisplayInfo] {
        let cacheId = chat.id
        if let cache = chatToMessagesCache[cacheId] {
            return cache.map { $0.displayInfo }
        }
        let chat = try getMessagingChatFor(displayInfo: chat)
        let messages = try await apiService.getMessagesForChat(chat, fetchLimit: fetchLimit)
        chatToMessagesCache[cacheId] = messages

        notifyMessagesChanges(chatId: cacheId)
        return messages.map { $0.displayInfo }
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChatDisplayInfo) throws -> MessagingChatMessageDisplayInfo {
        let cacheId = chat.id
        let messagingChat = try getMessagingChatFor(displayInfo: chat)
        var messages = chatToMessagesCache[cacheId] ?? []
        
        let newMessageDisplayInfo = MessagingChatMessageDisplayInfo(id: UUID().uuidString,
                                                                    chatId: chat.id,
                                                                    senderType: .thisUser(chat.thisUserDetails),
                                                                    time: Date(),
                                                                    type: messageType,
                                                                    isRead: false,
                                                                    deliveryState: .sending)
        
        let newMessage = MessagingChatMessage(displayInfo: newMessageDisplayInfo, serviceMetadata: nil)
        messages.append(newMessage)
        chatToMessagesCache[cacheId] = messages
        sendMessageToBE(message: newMessage, messageType: messageType, in: messagingChat)
        notifyMessagesChanges(chatId: cacheId)

        return newMessageDisplayInfo
    }
    
    func makeChatRequest(_ chat: MessagingChatDisplayInfo, approved: Bool) async throws {
        let chat = try getMessagingChatFor(displayInfo: chat)
        try await apiService.makeChatRequest(chat, approved: approved)
        // TODO: - Reload chats list?
    }
    
    func resendMessage(_ message: MessagingChatMessageDisplayInfo) throws {
        let cacheId = message.chatId
        let messagingChat = try getMessagingChatWith(chatId: cacheId)
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
    func getSubscribedChannelsFor(domain: DomainDisplayInfo) async throws -> [MessagingNewsChannel] {
        guard let wallet = domain.ownerWallet else { throw MessagingServiceError.domainWithoutWallet }
        if let channels = walletToChannelsCache[wallet] {
            return channels
        }
        
        let channels = try await apiService.getSubscribedChannelsFor(wallet: wallet)
        walletToChannelsCache[wallet] = channels
        return channels
    }
    
    func getNotificationsInboxFor(domain: DomainDisplayInfo,
                                  page: Int,
                                  limit: Int,
                                  isSpam: Bool) async throws -> [MessagingNewsChannelFeed] {
        guard let wallet = domain.ownerWallet else { throw MessagingServiceError.domainWithoutWallet }
        
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
    func getMessagingChatFor(displayInfo: MessagingChatDisplayInfo) throws -> MessagingChat {
        try getMessagingChatWith(chatId: displayInfo.id)
    }
    
    func getMessagingChatWith(chatId: String) throws -> MessagingChat {
        let allChats = walletsToChatsCache.reduce([MessagingChat](), { $0 + $1.value })
        guard let chat = allChats.first(where: { $0.displayInfo.id == chatId }) else { throw MessagingServiceError.chatNotFound }
        
        return chat
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
        case .chatReceivedMessage:
            return
        }
    }
    
    func notifyMessagesChanges(chatId: String) {
        let messages = (chatToMessagesCache[chatId] ?? []).map({ $0.displayInfo })
        notifyListenersChangedDataType(.messages(messages, chatId: chatId))
    }
    
    func notifyListenersChangedDataType(_ messagingDataType: MessagingDataType) {
        listenerHolders.forEach { holder in
            holder.listener?.messagingDataTypeDidUpdated(messagingDataType)
        }
    }
}

// MARK: - Open methods
extension MessagingService {
    enum MessagingServiceError: Error {
        case domainWithoutWallet
        case chatNotFound
    }
}
