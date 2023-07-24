//
//  XMTPMessagingAPIService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation

final class XMTPMessagingAPIService {
    
    private let messagingHelper = MessagingAPIServiceHelper()

}


// MARK: - MessagingAPIServiceProtocol
extension XMTPMessagingAPIService: MessagingAPIServiceProtocol {
    func getUserFor(domain: DomainItem) async throws -> MessagingChatUserProfile {
        let env = getCurrentXMTPEnvironment()
        let client = try await XMTP.Client.create(account: domain, options: .init(api: .init(env: env, isSecure: true)))
        try storeKeysDataFromClientIfNeeded(client, domain: domain)
        let userProfile = XMTPEntitiesTransformer.convertXMTPClientToChatUser(client)
        return userProfile
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

// MARK: - Private methods
private extension XMTPMessagingAPIService {
    func storeKeysDataFromClientIfNeeded(_ client: XMTP.Client, domain: DomainItem) throws {
        let wallet = try domain.getETHAddressThrowing()
        guard KeychainXMTPKeysStorage.instance.getKeysDataFor(identifier: wallet) == nil else { return } // Already saved
        
        try storeKeysDataFrom(client: client, domain: domain)
    }
    
    @discardableResult
    func storeKeysDataFrom(client: XMTP.Client, domain: DomainItem) throws -> Data {
        let wallet = try domain.getETHAddressThrowing()
        let keysData = try client.privateKeyBundle.serializedData()
        KeychainXMTPKeysStorage.instance.saveKeysData(keysData,
                                                      forIdentifier: wallet)
        return keysData
    }
    
    func getClientKeysDataFor(user: MessagingChatUserProfile,
                              env: XMTPEnvironment) async throws -> Data {
        let wallet = user.wallet
        if let key = KeychainXMTPKeysStorage.instance.getKeysDataFor(identifier: wallet) {
            return key
        }
        
        let domain = try await getAnyDomainItem(for: wallet)
        let client = try await XMTP.Client.create(account: domain, options: .init(api: .init(env: env, isSecure: true)))
        return try storeKeysDataFrom(client: client, domain: domain)
    }
    
    func getAnyDomainItem(for wallet: HexAddress) async throws -> DomainItem {
        try await messagingHelper.getAnyDomainItem(for: wallet)
    }
    
    func getCurrentXMTPEnvironment() -> XMTPEnvironment {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        return isTestnetUsed ? .dev : .production
    }
}

enum XMTP {
    struct Client {
        var privateKeyBundle: PrivateKeyBundle = .mock
        var address: String = ""
        static func create(account: SigningKey, options: ClientOptions? = nil) async throws -> Client {
            .init()
        }
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
extension DomainItem: SigningKey {
    var address: String { ownerWallet ?? "" }
    func sign(_ data: Data) async throws -> String { "" }
    func sign(message: String) async throws -> String { "" }
}

///////////////////////////////////////////////////////////////////////


protocol SigningKey {
    var address: String { get }
    func sign(_ data: Data) async throws -> String
    func sign(message: String) async throws -> String
}
/// Specify configuration options for creating a ``Client``.
struct ClientOptions {
    // Specify network options
    struct Api {
        var env: XMTPEnvironment = .dev
        var isSecure: Bool = true
        init(env: XMTPEnvironment = .dev, isSecure: Bool = true) {
            self.env = env
            self.isSecure = isSecure
        }
    }
    
    var api = Api()
    var codecs: [String] = []
    
    init(api: Api = Api(), codecs: [String] = []) {
        self.api = api
        self.codecs = codecs
    }
}
enum PrivateKeyBundle {
    case mock
    func serializedData() throws -> Data { Data() }
}
enum XMTPEnvironment: String {
    case dev = "dev.xmtp.network",
         production = "production.xmtp.network",
         local = "localhost"
}
