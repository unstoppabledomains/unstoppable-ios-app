//
//  HomeExplore.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.02.2024.
//

import SwiftUI

// Namespace
enum HomeExplore { }

extension HomeExplore {
    enum SearchDomainsType: String, CaseIterable, UDSegmentedControlItem {
        case global, local
        
        var title: String {
            switch self {
            case .global:
                return String.Constants.global.localized()
            case .local:
                return String.Constants.yours.localized()
            }
        }
        
        var icon: Image? {
            switch self {
            case .global:
                return .globeBold
            case .local:
                return .walletExternalIcon
            }
        }
        
        var analyticButton: Analytics.Button { .exploreDomainsSearchType }
    }
    
    struct TrendingProfile: Hashable, Identifiable {
        var id: String { domainName }
        
        let domainName: String
        let walletAddress: String
        let profileName: String
        let avatarURL: URL?
        let followersCount: Int
        
        init(domainName: String, walletAddress: String, avatarURL: URL?, profileName: String, followersCount: Int) {
            self.domainName = domainName
            self.walletAddress = walletAddress
            self.avatarURL = avatarURL
            self.profileName = profileName
            self.followersCount = followersCount
        }
        
        init(publicProfile: SerializedPublicDomainProfile) {
            self.domainName = publicProfile.metadata.domain
            self.walletAddress = publicProfile.metadata.owner
            self.profileName = publicProfile.profile.displayName?.trimmedSpaces ?? ""
            self.avatarURL = URL(string: publicProfile.profile.imagePath ?? "")
            self.followersCount = publicProfile.social?.followerCount ?? 0
        }
    }
}
