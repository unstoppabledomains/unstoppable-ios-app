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
    
    init(apiService: MessagingAPIServiceProtocol,
         webSocketsService: MessagingWebSocketsServiceProtocol,
         storageProtocol: MessagingStorageServiceProtocol) {
        self.apiService = apiService
        self.webSocketsService = webSocketsService
        self.storageProtocol = storageProtocol
    }
    
}

// MARK: - Open methods
extension MessagingService {
//    func getUserFor(domain: DomainItem) async throws -> ChatUser? {
//
//    }
}
