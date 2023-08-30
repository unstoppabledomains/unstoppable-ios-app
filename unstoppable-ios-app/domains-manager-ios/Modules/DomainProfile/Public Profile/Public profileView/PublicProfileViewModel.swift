//
//  PublicProfileViewModel.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 22.08.2023.
//

import SwiftUI

struct DomainProfileFollowerDisplayInfo: Hashable {
    let domain: String
    var icon: UIImage?
}

extension PublicProfileView {
    
    struct FollowersDisplayInfo {
        var topFollowersList: [DomainProfileFollowerDisplayInfo]
        var totalNumberOfFollowers: Int
    }
    
   @MainActor
    final class PublicProfileViewModel: ObservableObject, ProfileFollowerImageLoader {
        
        private(set) var domainName: DomainName
        let viewingDomain: DomainItem
        @Published var records: [String : String]?
        @Published var socialInfo: DomainProfileSocialInfo?
        @Published var socialAccounts: SocialAccounts?
        @Published private(set) var isLoading = false
        @Published private(set) var profile: SerializedPublicDomainProfile?
        @Published private(set) var badgesDisplayInfo: [DomainProfileBadgeDisplayInfo]?
        @Published private(set) var coverImage: UIImage?
        @Published private(set) var avatarImage: UIImage?
        @Published private(set) var isFollowing: Bool?
        @Published private(set) var followersDisplayInfo: FollowersDisplayInfo?
        private var badgesInfo: BadgesInfo?
        
        init(domain: DomainName,
             viewingDomain: DomainItem) {
            self.domainName = domain
            self.viewingDomain = viewingDomain
            loadAllProfileData()
        }
     
        func loadIconIfNeededFor(follower: DomainProfileFollowerDisplayInfo) {
            guard follower.icon == nil else { return }
            
            Task {
                let icon = await loadIconFor(follower: follower)
                if let i = followersDisplayInfo?.topFollowersList.firstIndex(where: { $0.domain == follower.domain }) {
                    followersDisplayInfo?.topFollowersList[i].icon = icon
                }
            }
        }
        
        func loadIconIfNeededFor(badge: DomainProfileBadgeDisplayInfo) {
            guard badge.icon == nil else { return }
            
            Task {
                let icon = await badge.loadBadgeIcon()
                if let i = badgesDisplayInfo?.firstIndex(where: { $0.badge.code == badge.badge.code }) {
                    badgesDisplayInfo?[i].icon = icon
                }
            }
        }
        
        func followButtonPressed() {
            guard let isFollowing else { return }
            
            Task {
                do {
                    if isFollowing {
                        try await NetworkService().unfollow(domainName, by: viewingDomain)
                    } else {
                        try await NetworkService().follow(domainName, by: viewingDomain)
                    }
                    self.isFollowing = !isFollowing
                } catch {
                    
                }
            }
        }
        
        func didSelectFollower(_ follower: DomainProfileFollowerDisplayInfo) {
            clearAllProfileData()
            domainName = follower.domain
            loadAllProfileData()
        }
        
        private func loadAllProfileData() {
            loadPublicProfile()
            loadBadgesInfo()
            loadFollowingState()
            loadFollowersList()
        }
        
        private func clearAllProfileData() {
            profile = nil
            records = nil
            socialInfo = nil
            socialAccounts = nil
            isFollowing = nil
            badgesInfo = nil
            badgesDisplayInfo = nil
            followersDisplayInfo = nil
        }
        
        private func loadPublicProfile() {
            isLoading = true
            Task {
                do {
                    profile = try await NetworkService().fetchPublicProfile(for: domainName,
                                                                            fields: [.profile, .records, .socialAccounts])
                    records = profile?.records
                    socialInfo = profile?.social
                    socialAccounts = profile?.socialAccounts
                    isLoading = false
                    loadImages()
                } catch {
                    
                }
            }
        }
        
        private func loadFollowingState() {
            Task {
                isFollowing = try await NetworkService().isDomain(viewingDomain.name, following: domainName)
            }
        }
        
        private func loadBadgesInfo() {
            Task {
                badgesInfo = try await NetworkService().fetchBadgesInfo(for: domainName)
                badgesDisplayInfo = badgesInfo?.badges.map({ DomainProfileBadgeDisplayInfo(badge: $0,
                                                                              isExploreWeb3Badge: false) })
            }
        }
       
        private func loadFollowersList() {
            Task {
                let response = try await NetworkService().fetchListOfFollowers(for: domainName,
                                                                               relationshipType: .followers,
                                                                               count: 3,
                                                                               cursor: nil)
                followersDisplayInfo = .init(topFollowersList: response.data.map({ DomainProfileFollowerDisplayInfo(domain: $0.domain) }),
                                             totalNumberOfFollowers: response.meta.totalCount)
            }
        }
        
        private func loadImages() {
            loadAvatar()
            loadCoverImage()
        }
        
        private func loadAvatar() {
            Task {
                if profile?.profile.imagePath != nil {
                    try? await Task.sleep(seconds: 1)
                    avatarImage = UIImage(named: "testava2")
                }
            }
        }
        
        private func loadCoverImage() {
            Task {
                if profile?.profile.coverPath != nil {
                    try? await Task.sleep(seconds: 0.5)
                    coverImage = UIImage(named: "testava")
                }
            }
        }
    }
    
}

extension PublicDomainProfileAttributes {
    static let empty = PublicDomainProfileAttributes(displayName: nil,
                                                     description: nil,
                                                     location: nil,
                                                     web2Url: nil,
                                                     imagePath: nil,
                                                     imageType: nil,
                                                     coverPath: nil,
                                                     phoneNumber: nil,
                                                     domainPurchased: nil)
    
    static let filled = PublicDomainProfileAttributes(displayName: "Oleg Kuplin",
                              description: "Unstoppable iOS developer",
                              location: "Danang",
                              web2Url: "ud.me/oleg.x",
                              imagePath: "nil",
                              imageType: .onChain,
                              coverPath: "nil",
                              phoneNumber: nil,
                              domainPurchased: nil)
}

func loadImageFrom(url: URL) async -> UIImage? {
    let urlRequest = URLRequest(url: url)
    guard let (imageData, _) = try? await URLSession.shared.data(for: urlRequest) else { return nil }
    
    return UIImage(data: imageData)
}
