//
//  DomainProfileNetworkServiceProtocol {.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.03.2024.
//

import Foundation

protocol DomainProfileNetworkServiceProtocol {
    func fetchPublicProfile(for domainName: DomainName, fields: Set<GetDomainProfileField>) async throws -> SerializedPublicDomainProfile
    @discardableResult
    func updateUserDomainProfile(for domain: DomainItem,
                                 request: ProfileUpdateRequest) async throws -> SerializedUserDomainProfile
    
    func fetchListOfFollowers(for domain: DomainName,
                              relationshipType: DomainProfileFollowerRelationshipType,
                              count: Int,
                              cursor: Int?) async throws -> DomainProfileFollowersResponse
    func follow(_ domainNameToFollow: String, by domain: DomainItem) async throws
    func unfollow(_ domainNameToUnfollow: String, by domain: DomainItem) async throws
}
