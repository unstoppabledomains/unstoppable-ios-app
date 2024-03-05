//
//  DomainProfilesServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation

protocol DomainProfilesServiceProtocol {
    func fetchPublicDomainProfileDisplayInfo(for domainName: DomainName) async throws -> PublicDomainProfileDisplayInfo
    func follow(_ domainNameToFollow: String, by domain: DomainDisplayInfo) async throws
    func unfollow(_ domainNameToUnfollow: String, by domain: DomainDisplayInfo) async throws
}
