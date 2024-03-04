//
//  DomainProfilesService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation

final class DomainProfilesService {
   
    private let storage = PublicDomainProfileDisplayInfoStorageService()
    
}

// MARK: - DomainProfilesServiceProtocol
extension DomainProfilesService: DomainProfilesServiceProtocol {
    func getCachedPublicDomainProfileDisplayInfo(for domainName: String) -> PublicDomainProfileDisplayInfo? {
        try? storage.retrieveProfileFor(domainName: domainName)
    }
    
    func getPublicDomainProfileDisplayInfo(for domainName: DomainName) async throws -> PublicDomainProfileDisplayInfo {
        let serializedProfile = try await NetworkService().fetchPublicProfile(for: domainName,
                                                                              fields: [.profile, .records])
        let profile = PublicDomainProfileDisplayInfo(serializedProfile: serializedProfile)
        storage.store(profile: profile)
        return profile
    }
    
    func loadFullListOfFollowersFor(domainName: DomainName, 
                                    relationshipType: DomainProfileFollowerRelationshipType) async throws -> [DomainName] {
        let numberOfFollowersToTake = 50
        var cursor: Int?
        var followersList: [DomainName] = []
        var canLoadMore = true
        
        while canLoadMore {
            let response = try await NetworkService().fetchListOfFollowers(for: domainName,
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
}
