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
    
    private var domainToUserCache: [String : ChatUser] = [:]
    
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
    func getChannelsForDomain(_ domain: DomainDisplayInfo,
                              page: Int,
                              limit: Int) async throws -> [ChatChannelType] {
        try await apiService.getChannels(for: domain, page: page, limit: limit)
    }
    
    func getNumberOfUnreadMessagesInChannelsForDomain(_ domain: DomainDisplayInfo) async throws -> Int {
        0
    }
    
    func getMessagesForChannel(_ channel: ChatChannelType,
                               fetchLimit: Int) async throws -> [ChatMessageType] {
        try await apiService.getMessagesForChannel(channel, fetchLimit: fetchLimit)
    }
}
