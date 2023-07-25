//
//  XMTPMessagingAPIService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import XMTP

final class XMTPMessagingAPIService {
    
    private let messagingHelper = MessagingAPIServiceHelper()

}

// MARK: - MessagingAPIServiceProtocol
extension XMTPMessagingAPIService: MessagingAPIServiceProtocol {
    func getUserFor(domain: DomainItem) async throws -> MessagingChatUserProfile {
        let env = getCurrentXMTPEnvironment()
        
        //TODO: - Check for .canMessage
        let wallet = try domain.getETHAddressThrowing()
        guard KeychainXMTPKeysStorage.instance.getKeysDataFor(identifier: wallet, env: env) != nil else {
            throw XMTPServiceError.userNotCreatedYet
        }
        
        let client = try await XMTP.Client.create(account: domain,
                                                  options: .init(api: .init(env: env,
                                                                            isSecure: true)))
        try storeKeysDataFromClientIfNeeded(client, domain: domain, env: env)
        let userProfile = XMTPEntitiesTransformer.convertXMTPClientToChatUser(client)
        return userProfile
    }
    
    func createUser(for domain: DomainItem) async throws -> MessagingChatUserProfile {
        let env = getCurrentXMTPEnvironment()
        let client = try await XMTP.Client.create(account: domain,
                                                  options: .init(api: .init(env: env,
                                                                            isSecure: true)))

        try storeKeysDataFromClientIfNeeded(client, domain: domain, env: env)
        let userProfile = XMTPEntitiesTransformer.convertXMTPClientToChatUser(client)
        return userProfile
    }
    
    func updateUserProfile(_ user: MessagingChatUserProfile, name: String, avatar: String) async throws {
        throw XMTPServiceError.unsupportedAction
    }
    
    func getChatsListForUser(_ user: MessagingChatUserProfile, page: Int, limit: Int) async throws -> [MessagingChat] {
        let env = getCurrentXMTPEnvironment()
        let client = try await getClientFor(user: user, env: env)
        let conversations = try await client.conversations.list()
        
        return conversations.compactMap({ XMTPEntitiesTransformer.convertXMTPChatToChat($0, userId: user.id,
                                                                                        userWallet: user.wallet,
                                                                                        isApproved: true) })
    }
    
    func getChatRequestsForUser(_ user: MessagingChatUserProfile, page: Int, limit: Int) async throws -> [MessagingChat] {
        []
    }
    
    func getBlockingStatusForChat(_ chat: MessagingChat) async throws -> MessagingPrivateChatBlockingStatus {
        .unblocked
    }
    
    func setUser(in chat: MessagingChat, blocked: Bool, by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.unsupportedAction
        
    }
    
    func getMessagesForChat(_ chat: MessagingChat, before message: MessagingChatMessage?, cachedMessages: [MessagingChatMessage], fetchLimit: Int, isRead: Bool, for user: MessagingChatUserProfile, filesService: MessagingFilesServiceProtocol) async throws -> [MessagingChatMessage] {
        
        throw XMTPServiceError.unsupportedAction
    }
    
    func isMessagesEncryptedIn(chatType: MessagingChatType) async -> Bool {
        true
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType, in chat: MessagingChat, by user: MessagingChatUserProfile, filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessage {
        throw XMTPServiceError.unsupportedAction
    }
    
    func sendFirstMessage(_ messageType: MessagingChatMessageDisplayType, to userInfo: MessagingChatUserDisplayInfo, by user: MessagingChatUserProfile, filesService: MessagingFilesServiceProtocol) async throws -> (MessagingChat, MessagingChatMessage) {
        throw XMTPServiceError.unsupportedAction
        
    }
    
    func makeChatRequest(_ chat: MessagingChat, approved: Bool, by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.unsupportedAction
    }
    
    func leaveGroupChat(_ chat: MessagingChat, by user: MessagingChatUserProfile) async throws {
        throw XMTPServiceError.unsupportedAction
    }
}

// MARK: - Private methods
private extension XMTPMessagingAPIService {
    func storeKeysDataFromClientIfNeeded(_ client: XMTP.Client,
                                         domain: DomainItem,
                                         env: XMTPEnvironment) throws {
        let wallet = try domain.getETHAddressThrowing()
        guard KeychainXMTPKeysStorage.instance.getKeysDataFor(identifier: wallet, env: env) == nil else { return } // Already saved
        
        let keysData = try client.privateKeyBundle.serializedData()
        KeychainXMTPKeysStorage.instance.saveKeysData(keysData,
                                                      forIdentifier: wallet, env: env)
    }
    
    func getClientFor(user: MessagingChatUserProfile,
                      env: XMTPEnvironment) async throws -> XMTP.Client {
        let wallet = user.wallet
        return try await getClientFor(wallet: wallet, env: env)
    }
    
    func getClientFor(domain: DomainItem,
                      env: XMTPEnvironment) async throws -> XMTP.Client {
        let wallet = try domain.getETHAddressThrowing()
        return try await getClientFor(wallet: wallet, env: env)
    }
    
    func getClientFor(wallet: String,
                      env: XMTPEnvironment) async throws -> XMTP.Client {
        if let keysData = KeychainXMTPKeysStorage.instance.getKeysDataFor(identifier: wallet, env: env) {
            return try await createClientUsing(keysData: keysData, env: env)
        }
        throw XMTPServiceError.noClientKeys
    }
    
    func createClientUsing(keysData: Data,
                           env: XMTPEnvironment) async throws -> XMTP.Client {
        let keys = try PrivateKeyBundle(serializedData: keysData)
        let client = try await XMTP.Client.from(bundle: keys,
                                                options: .init(api: .init(env: env)))
        return client
    }
    
    func getAnyDomainItem(for wallet: HexAddress) async throws -> DomainItem {
        try await messagingHelper.getAnyDomainItem(for: wallet)
    }
    
    func getCurrentXMTPEnvironment() -> XMTPEnvironment {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        return isTestnetUsed ? .dev : .production
    }
}


// MARK: - Open methods
extension XMTPMessagingAPIService {
    enum XMTPServiceError: String, Error {
        case unsupportedAction
        case noClientKeys
        case userNotCreatedYet

        public var errorDescription: String? { rawValue }
    }
}
extension DomainItem: SigningKey {
    var address: String { ownerWallet ?? "" }
    func sign(_ data: Data) async throws -> XMTP.Signature {
        .init()
    }
    
    func sign(message: String) async throws -> XMTP.Signature {
        .init()
    }
}
