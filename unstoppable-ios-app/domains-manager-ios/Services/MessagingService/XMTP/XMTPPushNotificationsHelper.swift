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
        try await makeRequestFor(topics: topics, accepted: nil, blocked: nil, by: client)
    }
    
    static func unsubscribeFromTopics(_ topics: [String], by client: Client) async throws {
        try await makeRequestFor(topics: topics, accepted: false, blocked: false, by: client)
    }
}

// MARK: - Private methods
private extension XMTPPushNotificationsHelper {
    static func makeRequestFor(topics: [String], accepted: Bool?, blocked: Bool?, by client: Client) async throws {
        do {
            let url = URL(string: "https://\(NetworkConfig.baseAPIHost)/messaging/xmtp/topics/register")!
            let subReq = try await buildSubscribeRequestFor(topics: topics,
                                                            accepted: accepted,
                                                            blocked: blocked,
                                                            by: client)
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
    
    static func buildSubscribeRequestFor(topics: [String],
                                         accepted: Bool? = nil,
                                         blocked: Bool? = nil,
                                         by client: Client) async throws -> SubscribeRequest {
        let ownerAddress = client.address
        let signedPublicKey = (try client.publicKeyBundle.serializedData()).base64EncodedString()
        let registrations = try await signTopics(topics, 
                                                 accepted: accepted,
                                                 blocked: blocked,
                                                 by: client)
        
        let subReq = SubscribeRequest(ownerAddress: ownerAddress,
                                      registrations: registrations,
                                      signedPublicKey: signedPublicKey)
        return subReq
    }
    
    static func signTopics(_ topics: [String],
                           accepted: Bool?,
                           blocked: Bool?,
                           by client: Client) async throws -> [Registration] {
        var registrations: [Registration] = []
        for topic in topics {
            let registration = try await signTopic(topic, 
                                                   accepted: accepted,
                                                   blocked: blocked,
                                                   by: client)
            registrations.append(registration)
        }
        return registrations
    }
    
    static func signTopic(_ topic: String,
                          accepted: Bool?,
                          blocked: Bool?,
                          by client: Client) async throws -> Registration {
        guard let topicData = topic.data(using: .utf8) else {
            throw XMTPPushNotificationError.failedToPrepareTopicData
        }
        let hashedTopicData = topicData.web3.keccak256
        let signature = try await signData(hashedTopicData, by: client)
        let registration = Registration(topic: topic,
                                        signature: signature,
                                        accept: accepted,
                                        block: blocked)
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
        let accept: Bool?
        let block: Bool?
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
