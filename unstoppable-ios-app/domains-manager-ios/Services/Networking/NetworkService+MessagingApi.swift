//
//  NetworkService+MessagingApi.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.10.2023.
//

import Foundation

extension NetworkService {
    
    struct JoinBadgeCommunityResponse: Codable {
        let groupChatId: String
    }
    
    private struct JoinAndLeaveCommunityRequestPayload: Codable {
        let address: String
        let badgeCode: String
        let signature: String
    }
    
    func joinBadgeCommunity(badge: BadgeDetailedInfo,
                            by wallet: String,
                            signature: String) async throws -> JoinBadgeCommunityResponse {
        let payload = JoinAndLeaveCommunityRequestPayload(address: wallet, 
                                                          badgeCode: badge.badge.code,
                                                          signature: signature)
        let body = try prepareRequestBodyFrom(entity: payload)
        let endpoint = Endpoint.joinBadgeCommunity(body: body)
       
        return try await fetchDecodableDataFor(endpoint: endpoint, method: .post)
    }
  
    func leaveBadgeCommunity(badge: BadgeDetailedInfo,
                             by wallet: String,
                             signature: String) async throws  {
        let payload = JoinAndLeaveCommunityRequestPayload(address: wallet, badgeCode: badge.badge.code, signature: signature)

        let body = try prepareRequestBodyFrom(entity: payload)
        let endpoint = Endpoint.leaveBadgeCommunity(body: body)
        
        try await fetchDataFor(endpoint: endpoint, method: .post)
    }
}
