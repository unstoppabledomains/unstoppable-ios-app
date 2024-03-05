//
//  PublicDomainProfileNetworkServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.03.2024.
//

import Foundation

protocol PublicDomainProfileNetworkServiceProtocol {
    func fetchPublicProfile(for domainName: DomainName, fields: Set<GetDomainProfileField>) async throws -> SerializedPublicDomainProfile
    func follow(_ domainNameToFollow: String, by domain: DomainItem) async throws
    func unfollow(_ domainNameToUnfollow: String, by domain: DomainItem) async throws
}
