//
//  XMTPPushNotificationsExtensionHelper.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.08.2023.
//

import Foundation
import XMTP

struct XMTPPushNotificationsExtensionHelper {
    struct NotificationDisplayInfo {
        let walletAddress: String
        let localizedMessage: String
    }
    
    static func parseNotificationMessageFrom(data: ExternalEvent.ChatXMTPMessageEventData) async -> NotificationDisplayInfo? {
        var address: String = data.toAddress
        var message: String = String.Constants.newChatMessage.localized()

        do {
            guard let encryptedMessageData = Data(base64Encoded: Data(data.envelop.utf8)) else { throw XMTPPushNotificationError.failedToGetEncryptedMessageData }
            
            let topic = data.topic
            let wallet = data.toAddress.ethChecksumAddress()
            let env: XMTPEnvironment = .production
            let client = try await getClientFor(wallet: wallet, env: env)
            
            let conversationData = AppGroupsBridgeService.shared.getXMTPConversationDataFor(topic: topic)
            let conversationContainer: XMTP.ConversationContainer = try decodeConversationData(from: conversationData)
            let conversation = conversationContainer.decode(with: client)
            address = conversation.peerAddress
            
            guard AppGroupsBridgeService.shared.getXMTPBlockedUsersList().first(where: { $0.userId == data.toAddress && $0.blockedUserId == address }) == nil else { return nil }// Ignore notification from blocked user
            
            let envelope = XMTP.Envelope.with { envelope in
                envelope.message = encryptedMessageData
                envelope.contentTopic = topic
            }
            let xmtpMessage = try conversation.decode(envelope)
            let typeID = xmtpMessage.encodedContent.type.typeID
            let knownType = XMTPEnvironmentNamespace.KnownType(rawValue: typeID)
            switch knownType {
            case .text:
                if let decryptedContent: String = try? xmtpMessage.content() {
                    message = decryptedContent
                }
            case .attachment, .remoteStaticAttachment, .none:
                Void()
            }
        } catch {
            Void()
        }
        return NotificationDisplayInfo(walletAddress: address,
                                       localizedMessage: message)
    }
    
    enum XMTPPushNotificationError: Error {
        case noClientKeys
        case failedToDecodeConversationData
        case failedToGetEncryptedMessageData
        case failedToParseMessage
    }
}

// MARK: - Private methods
private extension XMTPPushNotificationsExtensionHelper {
    static func decodeConversationData<T: Codable>(from data: Data?) throws -> T {
        guard let data else {
            throw XMTPPushNotificationError.failedToDecodeConversationData
        }
        guard let serviceMetadata = T.objectFromData(data) else {
            throw XMTPPushNotificationError.failedToDecodeConversationData
        }
        
        return serviceMetadata
    }
    
    static func getClientFor(wallet: String,
                             env: XMTPEnvironment) async throws -> XMTP.Client {
        if let keysData = KeychainXMTPKeysStorage.instance.getKeysDataFor(identifier: wallet, env: env) {
            return try await createClientUsing(keysData: keysData, env: env)
        }
        throw XMTPPushNotificationError.noClientKeys
    }
    
    static func createClientUsing(keysData: Data,
                                  env: XMTPEnvironment) async throws -> XMTP.Client {
        let keys = try PrivateKeyBundle(serializedData: keysData)
        let client = try await XMTP.Client.from(bundle: keys,
                                                options: .init(api: .init(env: env,
                                                                          appVersion: XMTPServiceSharedHelper.getXMTPVersion())))
        return client
    }
}
