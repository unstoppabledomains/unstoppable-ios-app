//
//  XMTPPushNotificationsHelper.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.08.2023.
//

import Foundation
import XMTP

struct XMTPPushNotificationsHelper {
    static func subscribeForTopics(_ topics: [String], by client: Client) async throws {
        do {
            let url = URL(string: "https://messaging.ud-staging.com/api/xmtp/topics/register")!
            let subReq = try await buildSubscribeRequestFor(topics: topics, by: client)
            let reqData = subReq.jsonString()!
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
        let signature = try await signString(topic, by: client)
        let registration = Registration(topic: topic, signature: signature)
        return registration
    }
    
    static func signString(_ str: String,
                           by client: Client) async throws -> String {
        let data = str.data(using: .utf8)!
        let signature = try await client.keys.preKeys.first!.sign(data)
        
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
}
