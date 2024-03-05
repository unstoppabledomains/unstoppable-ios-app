//
//  DomainProfilesService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation

final class DomainProfilesService {
   
    private let storage: PublicDomainProfileDisplayInfoStorageServiceProtocol
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService(),
         storage: PublicDomainProfileDisplayInfoStorageServiceProtocol) {
        self.networkService = networkService
        self.storage = storage
    }
    
}

// MARK: - DomainProfilesServiceProtocol
extension DomainProfilesService: DomainProfilesServiceProtocol {
    func getCachedPublicDomainProfileDisplayInfo(for domainName: String) -> PublicDomainProfileDisplayInfo? {
        try? storage.retrieveProfileFor(domainName: domainName)
    }
 
    func fetchPublicDomainProfileDisplayInfo(for domainName: DomainName) async throws -> PublicDomainProfileDisplayInfo {
        let serializedProfile = try await getSerializedPublicDomainProfile(for: domainName)
        let profile = PublicDomainProfileDisplayInfo(serializedProfile: serializedProfile)
        
        storage.store(profile: profile)
        
        return profile
    }
    
    func getCachedAndRefreshProfileStream(for domainName: DomainName) -> AsyncThrowingStream<PublicDomainProfileDisplayInfo, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if let cachedProfile = getCachedPublicDomainProfileDisplayInfo(for: domainName) {
                    continuation.yield(cachedProfile)
                }
                
                let refreshedProfile = try await fetchPublicDomainProfileDisplayInfo(for: domainName)
                continuation.yield(refreshedProfile)
                                
                continuation.finish()
            }
        }
    }
    
    func loadFullListOfFollowersFor(domainName: DomainName,
                                    relationshipType: DomainProfileFollowerRelationshipType) async throws -> [DomainName] {
        let numberOfFollowersToTake = 50
        var cursor: Int?
        var followersList: [DomainName] = []
        var canLoadMore = true
        
        while canLoadMore {
            let response = try await networkService.fetchListOfFollowers(for: domainName,
                                                                         relationshipType: relationshipType,
                                                                         count: numberOfFollowersToTake,
                                                                         cursor: cursor)
            let responseDomainNames = response.data.map { $0.domain }
            followersList.append(contentsOf: responseDomainNames)
            
            cursor = response.meta.pagination.cursor
            canLoadMore = responseDomainNames.count == numberOfFollowersToTake
        }
        
        return followersList
    }
    
    func follow(_ domainNameToFollow: String, by domain: DomainDisplayInfo) async throws {
        try await networkService.follow(domainNameToFollow, by: domain.toDomainItem())
    }
    
    func unfollow(_ domainNameToUnfollow: String, by domain: DomainDisplayInfo) async throws {
        try await networkService.unfollow(domainNameToUnfollow, by: domain.toDomainItem())
    }
}

// MARK: - Private methods
private extension DomainProfilesService {
    func getSerializedPublicDomainProfile(for domainName: DomainName) async throws -> SerializedPublicDomainProfile {
        let serializedProfile = try await networkService.fetchPublicProfile(for: domainName,
                                                                            fields: [.profile, .records, .socialAccounts])
        return serializedProfile
    }
}
