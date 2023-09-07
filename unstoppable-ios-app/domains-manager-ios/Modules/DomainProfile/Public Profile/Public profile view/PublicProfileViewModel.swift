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
    
    enum PublicProfileError: Error {
        case failedToLoadFollowerInfo
    }
    
   @MainActor
    final class PublicProfileViewModel: ObservableObject, ProfileImageLoader, ViewErrorHolder {
        
        private(set) var domain: PublicDomainDisplayInfo
        private(set) var viewingDomain: DomainItem
        @Published var records: [String : String]?
        @Published var socialInfo: DomainProfileSocialInfo?
        @Published var socialAccounts: SocialAccounts?
        @Published var error: Error?
        @Published private(set) var isLoading = false
        @Published private(set) var profile: SerializedPublicDomainProfile?
        @Published private(set) var badgesDisplayInfo: [DomainProfileBadgeDisplayInfo]?
        @Published private(set) var coverImage: UIImage?
        @Published private(set) var avatarImage: UIImage?
        @Published private(set) var viewingDomainImage: UIImage?
        @Published private(set) var isFollowing: Bool?
        @Published private(set) var followersDisplayInfo: FollowersDisplayInfo?
        private var appearTime: Date
        private var badgesInfo: BadgesInfo?
        
        init(domain: PublicDomainDisplayInfo,
             viewingDomain: DomainItem) {
            self.domain = domain
            self.viewingDomain = viewingDomain
            self.appearTime = Date()
            loadAllProfileData()
            loadViewingDomainData()
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
            guard badge.icon == nil,
                let i = badgesDisplayInfo?.firstIndex(where: { $0.badge.code == badge.badge.code }) else { return }
            
            Task {
                let icon = await badge.loadBadgeIcon()
                badgesDisplayInfo?[i].icon = icon
            }
        }
        
        func followButtonPressed() {
            guard let isFollowing else { return }
            
            Task {
                await performAsyncErrorCatchingBlock {
                    if isFollowing {
                        try await NetworkService().unfollow(domain.name, by: viewingDomain)
                    } else {
                        try await NetworkService().follow(domain.name, by: viewingDomain)
                    }
                    self.isFollowing = !isFollowing
                    loadPublicProfile() // Refresh social info
                }
            }
        }
        
        func didSelectFollower(_ follower: DomainProfileFollowerDisplayInfo) {
            Task {
                guard let rrInfo = try? await NetworkService().fetchGlobalReverseResolution(for: follower.domain) else {
                    self.error = PublicProfileError.failedToLoadFollowerInfo
                    return
                }
                clearAllProfileData()
                domain = .init(walletAddress: rrInfo.address,
                               name: follower.domain)
                loadAllProfileData()
            }
        }
        
        func didSelectViewingDomain(_ domain: DomainItem) {
            viewingDomainImage = nil
            isFollowing = nil
            loadFollowingState()
            viewingDomain = domain
            loadViewingDomainData()
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
            avatarImage = nil
            coverImage = nil
            appearTime = Date()
        }
        
        private func loadPublicProfile() {
            isLoading = true
            Task {
                await performAsyncErrorCatchingBlock {
                    let profile = try await NetworkService().fetchPublicProfile(for: domain.name,
                                                                                fields: [.profile, .records, .socialAccounts])
                    await waitForAppear()
                    self.profile = profile
                    records = profile.records
                    socialInfo = profile.social
                    socialAccounts = profile.socialAccounts
                    isLoading = false
                    loadImages()
                }
            }
        }
        
        private func loadFollowingState() {
            Task {
                await performAsyncErrorCatchingBlock {
                    let isFollowing = try await NetworkService().isDomain(viewingDomain.name, following: domain.name)
                    await waitForAppear()
                    self.isFollowing = isFollowing
                    // Hack for SwiftUI doesn't update button status 
                    try? await Task.sleep(seconds: 0.1)
                    self.isFollowing = isFollowing
                }
            }
        }
        
        private func loadBadgesInfo() {
            Task {
                await performAsyncErrorCatchingBlock {
                    let badgesInfo = try await NetworkService().fetchBadgesInfo(for: domain.name)
                    await waitForAppear()
                    self.badgesInfo = badgesInfo
                    badgesDisplayInfo = badgesInfo.badges.map({ DomainProfileBadgeDisplayInfo(badge: $0,
                                                                                              isExploreWeb3Badge: false) })
                }
            }
        }
       
        private func loadFollowersList() {
            Task {
                await performAsyncErrorCatchingBlock {
                    let response = try await NetworkService().fetchListOfFollowers(for: domain.name,
                                                                                   relationshipType: .followers,
                                                                                   count: 3,
                                                                                   cursor: nil)
                    await waitForAppear()
                    followersDisplayInfo = .init(topFollowersList: response.data.map({ DomainProfileFollowerDisplayInfo(domain: $0.domain) }),
                                                 totalNumberOfFollowers: response.meta.totalCount)
                }
            }
        }
        
        private func loadImages() {
            loadAvatar()
            loadCoverImage()
        }
        
        private func loadAvatar() {
            Task {
                if let imagePath = profile?.profile.imagePath,
                   let url = URL(string: imagePath) {
                    let avatarImage = await appContext.imageLoadingService.loadImage(from: .url(url),
                                                                                 downsampleDescription: nil)
                    await waitForAppear()
                    self.avatarImage = avatarImage
                }
            }
        }
        
        private func loadCoverImage() {
            Task {
                if let coverPath = profile?.profile.coverPath,
                   let url = URL(string: coverPath) {
                    let coverImage = await appContext.imageLoadingService.loadImage(from: .url(url),
                                                                                downsampleDescription: nil)
                    await waitForAppear()
                    self.coverImage = coverImage
                }
            }
        }
        
        private func loadViewingDomainData() {
            Task {
                let domains = await appContext.dataAggregatorService.getDomainsDisplayInfo()
                guard let displayInfo = domains.first(where: { $0.isSameEntity(viewingDomain) }) else { return }
                
                let viewingDomainImage = await appContext.imageLoadingService.loadImage(from: .domain(displayInfo),
                                                                                    downsampleDescription: nil)
                await waitForAppear()
                self.viewingDomainImage = viewingDomainImage
            }
        }
        
        private func waitForAppear() async {
            let timeSinceViewAppear = Date().timeIntervalSince(appearTime)
            let uiReadyTime = 0.5
            
            let dif = uiReadyTime - timeSinceViewAppear
            if dif > 0 {
                try? await Task.sleep(seconds: dif)
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
