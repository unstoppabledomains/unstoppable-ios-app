//
//  XMTPServiceHelper.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.07.2023.
//

import Foundation
import XMTP

struct XMTPServiceHelper {
    static func getCurrentXMTPEnvironment() -> XMTPEnvironment {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        return isTestnetUsed ? .dev : .production
    }
    
    static func getClientFor(user: MessagingChatUserProfile,
                             env: XMTPEnvironment) async throws -> XMTP.Client {
        let wallet = user.wallet
        return try await getClientFor(wallet: wallet, env: env)
    }
    
    static func getClientFor(domain: DomainItem,
                             env: XMTPEnvironment) async throws -> XMTP.Client {
        let wallet = try domain.getETHAddressThrowing()
        return try await getClientFor(wallet: wallet, env: env)
    }
    
    static func getClientFor(wallet: String,
                             env: XMTPEnvironment) async throws -> XMTP.Client {
        if let keysData = KeychainXMTPKeysStorage.instance.getKeysDataFor(identifier: wallet, env: env) {
            return try await createClientUsing(keysData: keysData, env: env)
        }
        throw XMTPHelperError.noClientKeys
    }
    
    static func createClientUsing(keysData: Data,
                                  env: XMTPEnvironment) async throws -> XMTP.Client {
        let keys = try PrivateKeyBundle(serializedData: keysData)
        let client = try await XMTP.Client.from(bundle: keys,
                                                options: .init(api: .init(env: env,
                                                                          appVersion: XMTPServiceSharedHelper.getXMTPVersion())))
        client.register(codec: AttachmentCodec())
        client.register(codec: RemoteAttachmentCodec())
        return client
    }
    
    /// In XMTP user considered as not approved (pending request) if it is in neither approved or blocked list.
    static func getListOfApprovedAddressesForUser(_ user: MessagingChatUserProfile) -> Set<String> {
        Set(
            XMTPApprovedTopicsStorage.shared.getApprovedTopicsListFor(userId: user.id).map { $0.approvedAddress } +
            XMTPBlockedUsersStorage.shared.getBlockedTopicsListFor(userId: user.id).map { $0.blockedAddress }
        )
    }
}

// MARK: - Open methods
extension XMTPServiceHelper {
    enum XMTPHelperError: String, Error {
        case noClientKeys

        public var errorDescription: String? { rawValue }

    }
}
