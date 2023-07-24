//
//  XMTPMessagingAPIService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation

final class XMTPMessagingAPIService {
    
    
}


// MARK: - MessagingAPIServiceProtocol
extension XMTPMessagingAPIService: MessagingAPIServiceProtocol {
    func getUserFor(domain: DomainItem) async throws -> MessagingChatUserProfile {
        throw XMTPServiceError.noDomainForWallet
    }
    
    func createUser(for domain: DomainItem) async throws -> MessagingChatUserProfile {
        throw XMTPServiceError.noDomainForWallet
        
    }
    
    func updateUserProfile(_ user: MessagingChatUserProfile, name: String, avatar: String) async throws {
        throw XMTPServiceError.noDomainForWallet
        
    }
    
    func getChatsListForUser(_ user: MessagingChatUserProfile, page: Int, limit: Int) async throws -> [MessagingChat] {
        throw XMTPServiceError.noDomainForWallet
        
    }
    
    func getChatRequestsForUser(_ user: MessagingChatUserProfile, page: Int, limit: Int) async throws -> [MessagingChat] {
        throw XMTPServiceError.noDomainForWallet
        
    }
    
    func getBlockingStatusForChat(_ chat: MessagingChat) async throws -> MessagingPrivateChatBlockingStatus {
        throw XMTPServiceError.noDomainForWallet
        
    }
    
    func setUser(in chat: MessagingChat, blocked: Bool, by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.noDomainForWallet
        
    }
    
    func getMessagesForChat(_ chat: MessagingChat, before message: MessagingChatMessage?, cachedMessages: [MessagingChatMessage], fetchLimit: Int, isRead: Bool, for user: MessagingChatUserProfile, filesService: MessagingFilesServiceProtocol) async throws -> [MessagingChatMessage] {
        
        throw XMTPServiceError.noDomainForWallet
    }
    
    func isMessagesEncryptedIn(chatType: MessagingChatType) async -> Bool {
        true
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType, in chat: MessagingChat, by user: MessagingChatUserProfile, filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessage {
        throw XMTPServiceError.noDomainForWallet
    }
    
    func sendFirstMessage(_ messageType: MessagingChatMessageDisplayType, to userInfo: MessagingChatUserDisplayInfo, by user: MessagingChatUserProfile, filesService: MessagingFilesServiceProtocol) async throws -> (MessagingChat, MessagingChatMessage) {
        throw XMTPServiceError.noDomainForWallet
        
    }
    
    func makeChatRequest(_ chat: MessagingChat, approved: Bool, by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.unsupportedAction
    }
    
    func leaveGroupChat(_ chat: MessagingChat, by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.unsupportedAction
    }
}

// MARK: - Open methods
extension XMTPMessagingAPIService {
    enum XMTPServiceError: String, Error {
        case unsupportedAction
        case noDomainForWallet

        public var errorDescription: String? { rawValue }
    }
}
