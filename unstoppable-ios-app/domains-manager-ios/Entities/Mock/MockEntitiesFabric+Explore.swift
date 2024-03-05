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
        
        static func createTrendingProfiles() -> [HomeExplore.ExploreDomainProfile] {
            [.init(domainName: "trendingprofile.x", walletAddress: "1", avatarURL: nil, profileName: "", followersCount: 0),
             .init(domainName: "trendingprofile.crypto", walletAddress: "2", avatarURL: ImageURLs.aiAvatar.url, profileName: "", followersCount: 0),
             .init(domainName: "trendingprofile.wallet", walletAddress: "3", avatarURL: ImageURLs.sunset.url, profileName: "Captain bitcoin", followersCount: 0),
             .init(domainName: "trendingprofile.pudgy", walletAddress: "4", avatarURL: nil, profileName: "", followersCount: 18768),
             .init(domainName: "trendingprofilewithlonglongdomainnamethatcantfitAnywhere.wallet", walletAddress: "5", avatarURL: ImageURLs.aiAvatar.url, profileName: "Captain bitcoin", followersCount: 1),
             .init(domainName: "hey.hi", walletAddress: "6", avatarURL: ImageURLs.aiAvatar.url, profileName: "Captain bitcoin withlonglongdomainnamethatcantfitAnywhere", followersCount: 173)]
        }
    }
}

