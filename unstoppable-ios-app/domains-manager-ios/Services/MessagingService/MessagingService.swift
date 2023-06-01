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
    private var chatToMessagesCache: [String : [MessagingChatMessage]] = [:]
    
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
        return chats.map { $0.displayInfo }
    }
    
    // Fetch limit is 30 max
    func getMessagesForChat(_ chat: MessagingChatDisplayInfo,
                            fetchLimit: Int) async throws -> [MessagingChatMessageDisplayInfo] {
        let cacheId = chat.id
        if let cache = chatToMessagesCache[cacheId] {
            return cache.map { $0.displayInfo }
        }
        let allChats = walletsToChatsCache.reduce([MessagingChat](), { $0 + $1.value })
        guard let chat = allChats.first(where: { $0.displayInfo.id == chat.id }) else { throw MessagingServiceError.chatNotFound }
                
        let messages = try await apiService.getMessagesForChat(chat, fetchLimit: fetchLimit)
        chatToMessagesCache[cacheId] = messages

        return messages.map { $0.displayInfo }
    }
}

// MARK: - Open methods
extension MessagingService {
    enum MessagingServiceError: Error {
        case domainWithoutWallet
        case chatNotFound
    }
}
