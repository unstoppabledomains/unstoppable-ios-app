//
//  XMTPPushNotificationsHelper.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.08.2023.
//

import Foundation
import XMTP
import web3

struct XMTPPushNotificationsHelper {
    static func subscribeForTopics(_ topics: [String], by client: Client) async throws {
        do {
            let url = URL(string: "https://\(NetworkConfig.baseMessagingHost)/api/xmtp/topics/register")!
            let subReq = try await buildSubscribeRequestFor(topics: topics, by: client)
            guard let reqData = subReq.jsonString() else {
                throw XMTPPushNotificationError.failedToPrepareRequestData
            }
            let request = APIRequest(url: url,
                                     body: reqData,
                                     method: .post)
            _ = try await NetworkService().makeAPIRequest(request)
        } catch {
            Debugger.printFailure("Failed to subscribe for PN XMTP topics")
        }
    }
    
    static func unsubscribeFromTopics(_ topics: [String], by client: Client) async throws {
        
        
    }
}

// MARK: - Private methods
private extension XMTPPushNotificationsHelper {
    static func buildSubscribeRequestFor(topics: [String],
                                         by client: Client) async throws -> SubscribeRequest {
        let ownerAddress = client.address
        let signedPublicKey = (try client.publicKeyBundle.serializedData()).base64EncodedString()
        let registrations = try await signTopics(topics, by: client)
        
        let subReq = SubscribeRequest(ownerAddress: ownerAddress,
                                      registrations: registrations,
                                      signedPublicKey: signedPublicKey)
        return subReq
    }
    
    static func signTopics(_ topics: [String],
                           by client: Client) async throws -> [Registration] {
        var registrations: [Registration] = []
        for topic in topics {
            let registration = try await signTopic(topic, by: client)
            registrations.append(registration)
        }
        return registrations
    }
    
    static func signTopic(_ topic: String,
                          by client: Client) async throws -> Registration {
        guard let topicData = topic.data(using: .utf8) else {
            throw XMTPPushNotificationError.failedToPrepareTopicData
        }
        let hashedTopicData = topicData.web3.keccak256
        let signature = try await signData(hashedTopicData, by: client)
        let registration = Registration(topic: topic, signature: signature)
        return registration
    }
    
    static func signData(_ data: Data,
                           by client: Client) async throws -> String {
        guard let preKey = client.keys.preKeys.first else {
            throw XMTPPushNotificationError.noPreKeysInXMTPClient
        }
        let signature = try await preKey.sign(data)
        
        return try signature.serializedData().base64EncodedString()
    }
    
    struct Registration: Codable {
        let topic: String
        let signature: String
    }
    
    struct SubscribeRequest: Codable {
        let ownerAddress: String
        let registrations: [Registration]
        let signedPublicKey: String
    }
    
    enum XMTPPushNotificationError: Error {
        case failedToPrepareTopicData
        case noPreKeysInXMTPClient
        case failedToPrepareRequestData
    }
}
