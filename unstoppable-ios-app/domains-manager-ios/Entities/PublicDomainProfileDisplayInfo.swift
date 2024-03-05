//
//  PublicDomainProfileDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation

struct PublicDomainProfileDisplayInfo: Hashable {
    let domainName: String
    let ownerWallet: String
    let profileName: String?
    let pfpURL: URL?
    let imageType: DomainProfileImageType?
    let bannerURL: URL?
    let description: String?
    let web2Url: String?
    let location: String?
    
    let records: [String : String]
    let socialAccounts: [DomainProfileSocialAccount]
    let followingCount: Int
    let followerCount: Int
    
    func numberOfFollowersFor(relationshipType: DomainProfileFollowerRelationshipType) -> Int {
        switch relationshipType {
        case .followers:
            followerCount
        case .following:
            followingCount
        }
    }
    
}

extension PublicDomainProfileDisplayInfo {
    init(serializedProfile: SerializedPublicDomainProfile) {
        self.domainName = serializedProfile.metadata.domain
        self.ownerWallet = serializedProfile.metadata.owner
        self.profileName = serializedProfile.profile.displayName
        self.pfpURL = URL(string: serializedProfile.profile.imagePath ?? "")
        self.imageType = serializedProfile.profile.imageType
        self.bannerURL = URL(string: serializedProfile.profile.coverPath ?? "")
        self.description = serializedProfile.profile.description
        self.web2Url = serializedProfile.profile.web2Url
        self.location = serializedProfile.profile.location
        self.records = serializedProfile.records ?? [:]
        self.socialAccounts = DomainProfileSocialAccount.typesFrom(accounts: serializedProfile.socialAccounts ?? .init())
        self.followingCount = serializedProfile.social?.followingCount ?? 0
        self.followerCount = serializedProfile.social?.followerCount ?? 0
    }
}
