//
//  MockEntitiesFabric+Explore.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.02.2024.
//

import Foundation

// MARK: - Explore
extension MockEntitiesFabric {
    enum Explore {
        @MainActor
        static func createViewModel() -> HomeExploreViewModel {
            createViewModelUsing(Home.createHomeTabRouter())
        }
        
        @MainActor
        static func createViewModelUsing(_ router: HomeTabRouter) -> HomeExploreViewModel {
            HomeExploreViewModel(router: router)
        }
        
        static func createFollowersProfiles() -> [SerializedPublicDomainProfile] {
            [DomainProfile.createPublicProfile(), // Empty
             DomainProfile.createPublicProfile(attributes: DomainProfile.createPublicProfileAttributes(imagePath: ImageURLs.aiAvatar.rawValue)), // Avatar
             DomainProfile.createPublicProfile(attributes: DomainProfile.createPublicProfileAttributes(coverPath: ImageURLs.sunset.rawValue)), // Cover path
             DomainProfile.createPublicProfile(attributes: DomainProfile.createPublicProfileAttributes(imagePath: ImageURLs.aiAvatar.rawValue, coverPath: ImageURLs.sunset.rawValue))] // Avatar and cover 1
        }
        
        static func createTrendingProfiles() -> [SerializedRankingDomain] {
            [.init(rank: 1, domain: "trendingprofile.x"),
             .init(rank: 2, domain: "trendingprofile.crypto"),
             .init(rank: 3, domain: "trendingprofile.wallet"),
             .init(rank: 4, domain: "trendingprofile.pudgy"),
             .init(rank: 5, domain: "trendingprofilewithlonglongdomainnamethatcantfitAnywhere.wallet"),
             .init(rank: 6, domain: "hey.hi")]
        }
    }
}

