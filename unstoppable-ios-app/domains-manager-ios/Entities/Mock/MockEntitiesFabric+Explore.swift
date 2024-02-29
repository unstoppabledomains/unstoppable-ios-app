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
            .init(router: Home.createHomeTabRouter())
        }
        
        static func createFollowersProfiles() -> [SerializedPublicDomainProfile] {
            [DomainProfile.createPublicProfile(), // Empty
             DomainProfile.createPublicProfile(attributes: DomainProfile.createPublicProfileAttributes(imagePath: ImageURLs.aiAvatar.rawValue)), // Avatar
             DomainProfile.createPublicProfile(attributes: DomainProfile.createPublicProfileAttributes(coverPath: ImageURLs.sunset.rawValue)), // Cover path
             DomainProfile.createPublicProfile(attributes: DomainProfile.createPublicProfileAttributes(imagePath: ImageURLs.aiAvatar.rawValue, coverPath: ImageURLs.sunset.rawValue))] // Avatar and cover 1
        }
        
        static func createTrendingProfiles() -> [HomeExplore.TrendingProfile] {
            [.init(domainName: "trendingprofile.x", avatarURL: nil, profileName: "", followersCount: 0),
             .init(domainName: "trendingprofile.crypto", avatarURL: ImageURLs.aiAvatar.url, profileName: "", followersCount: 0),
             .init(domainName: "trendingprofile.wallet", avatarURL: ImageURLs.sunset.url, profileName: "Captain bitcoin", followersCount: 0),
             .init(domainName: "trendingprofile.pudgy", avatarURL: nil, profileName: "", followersCount: 18768),
             .init(domainName: "trendingprofilewithlonglongdomainnamethatcantfitAnywhere.wallet", avatarURL: ImageURLs.aiAvatar.url, profileName: "Captain bitcoin", followersCount: 1),
             .init(domainName: "hey.hi", avatarURL: ImageURLs.aiAvatar.url, profileName: "Captain bitcoin withlonglongdomainnamethatcantfitAnywhere", followersCount: 173)]
        }
    }
}

