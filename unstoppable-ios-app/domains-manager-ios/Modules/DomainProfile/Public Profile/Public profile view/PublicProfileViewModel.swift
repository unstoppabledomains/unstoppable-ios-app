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

extension Array where Element == DomainProfileFollowerDisplayInfo {
    func getFirstIndexForFollowerDomain(_ follower: DomainProfileFollowerDisplayInfo) -> Int? {
        firstIndex(where: { $0.domain == follower.domain })
    }
}

extension PublicProfileView {
    
    struct FollowersDisplayInfo {
        var topFollowersList: [DomainProfileFollowerDisplayInfo]
        var totalNumberOfFollowers: Int
    }
    
    enum PublicProfileError: Error {
        case failedToLoadFollowerInfo
        case failedToFindDomain
    }
    
   @MainActor
    final class PublicProfileViewModel: ObservableObject, ProfileImageLoader, ViewErrorHolder {
        
        private weak var delegate: PublicProfileViewDelegate?
        private(set) var domain: PublicDomainDisplayInfo
        private(set) var viewingDomain: DomainDisplayInfo?
        @Published var records: [CryptoRecord]?
        @Published var socialInfo: DomainProfileSocialInfo?
        @Published var socialAccounts: [DomainProfileSocialAccount]?
        @Published var tokens: [BalanceTokenUIDescription]?
        @Published var isTokensCollapsed = true
        @Published var error: Error?
        @Published private(set) var isLoading = false
        @Published private(set) var isUserDomainSelected = true
        @Published private(set) var profile: DomainProfileDisplayInfo?
        @Published private(set) var badgesDisplayInfo: [DomainProfileBadgeDisplayInfo]?
        @Published private(set) var coverImage: UIImage?
        @Published private(set) var avatarImage: UIImage?
        @Published private(set) var viewingDomainImage: UIImage?
        @Published private(set) var isFollowing: Bool?
        @Published private(set) var followersDisplayInfo: FollowersDisplayInfo?
        private var appearTime: Date
        private var badgesInfo: BadgesInfo?
        private var preRequestedAction: PreRequestedProfileAction?
        
        init(domain: PublicDomainDisplayInfo,
             wallet: WalletEntity,
             viewingDomain: DomainDisplayInfo?,
             preRequestedAction: PreRequestedProfileAction?,
             delegate: PublicProfileViewDelegate?) {
            self.domain = domain
            self.viewingDomain = viewingDomain ?? wallet.getDomainToViewPublicProfile()
            self.preRequestedAction = preRequestedAction
            self.delegate = delegate
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
            guard let viewingDomain,
                let isFollowing else { return }
            
            Task {
                await performAsyncErrorCatchingBlock {
                    if isFollowing {
                        try await appContext.domainProfilesService.unfollowProfileWith(domainName: domain.name, by: viewingDomain)
                    } else {
                        try await appContext.domainProfilesService.followProfileWith(domainName: domain.name, by: viewingDomain)
                    }
                    self.isFollowing?.toggle()
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
        
        func didSelectViewingDomain(_ domain: DomainDisplayInfo) {
            viewingDomainImage = nil
            isFollowing = nil
            loadFollowingState()
            viewingDomain = domain
            loadViewingDomainData()
        }
        
        private func loadAllProfileData() {
            loadPublicProfile()
            loadProfileTokens()
            loadBadgesInfo()
            loadFollowingState()
            loadFollowersList()
        }
        
        private func clearAllProfileData() {
            profile = nil
            isUserDomainSelected = true
            records = nil
            socialInfo = nil
            socialAccounts = nil
            tokens = nil
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
                    let profile = try await appContext.domainProfilesService.fetchDomainProfileDisplayInfo(for: domain.name)
                    let domains = appContext.walletsDataService.wallets.combinedDomains()
                    await waitForAppear()
                    self.profile = profile
                    isUserDomainSelected = domains.first(where: { $0.name == domain.name }) != nil
                    records = await convertRecordsFrom(recordsDict: profile.records)
                    socialInfo = .init(followingCount: profile.followingCount, followerCount: profile.followerCount)
                    socialAccounts = profile.socialAccounts
                    isLoading = false
                    loadImages()
                }
            }
        }
        
        private func loadProfileTokens() {
            Task {
                await performAsyncErrorCatchingBlock {
                    let balances = try await appContext.walletsDataService.loadBalanceFor(walletAddress: domain.walletAddress)
                    tokens = balances.map { BalanceTokenUIDescription.extractFrom(walletBalance: $0) }.flatMap({ $0 })
                }
            }
        }
        
        private func convertRecordsFrom(recordsDict: [String: String]) async -> [CryptoRecord] {
            let currencies = await appContext.coinRecordsService.getCurrencies()
            let recordsData = DomainRecordsData(from: recordsDict,
                                                coinRecords: currencies,
                                                resolver: nil)
            return recordsData.records
        }
        
        private func loadFollowingState() {
            guard let viewingDomain else { return }
            
            Task {
                await performAsyncErrorCatchingBlock {
                    let isFollowing = try await NetworkService().isDomain(viewingDomain.name, following: domain.name)
                    await waitForAppear()
                    self.isFollowing = isFollowing
                    // Hack for SwiftUI doesn't update button status 
                    await Task.sleep(seconds: 0.1)
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
                    openPreRequestedBadgeIfNeeded(using: badgesInfo)
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
                if let pfpURL = profile?.pfpURL {
                    let avatarImage = await appContext.imageLoadingService.loadImage(from: .url(pfpURL),
                                                                                     downsampleDescription: .mid)
                    await waitForAppear()
                    self.avatarImage = avatarImage
                }
            }
        }
        
        private func loadCoverImage() {
            Task {
                if let bannerURL = profile?.bannerURL {
                    let coverImage = await appContext.imageLoadingService.loadImage(from: .url(bannerURL),
                                                                                    downsampleDescription: .mid)
                    await waitForAppear()
                    self.coverImage = coverImage
                }
            }
        }
        
        private func loadViewingDomainData() {
            guard let viewingDomain else { return }
            
            Task {
                let viewingDomainImage = await appContext.imageLoadingService.loadImage(from: .domain(viewingDomain),
                                                                                        downsampleDescription: .icon)
                await waitForAppear()
                self.viewingDomainImage = viewingDomainImage
            }
        }
        
        private func waitForAppear() async {
            let timeSinceViewAppear = Date().timeIntervalSince(appearTime)
            let uiReadyTime = 0.5
            
            let dif = uiReadyTime - timeSinceViewAppear
            if dif > 0 {
                await Task.sleep(seconds: dif)
            }
        }
        
        private func openPreRequestedBadgeIfNeeded(using badgesInfo: BadgesInfo) {
            switch preRequestedAction {
            case .showBadge(let code):
                if let badge = badgesInfo.badges.first(where: { $0.code == code }) {
                    let badgeDisplayInfo = DomainProfileBadgeDisplayInfo(badge: badge, isExploreWeb3Badge: false)
                    delegate?.publicProfileDidSelectBadge(badgeDisplayInfo, in: domain.name)
                }
            case .none:
                return
            }
            self.preRequestedAction = nil
        }
    }
    
}

func loadImageFrom(url: URL) async -> UIImage? {
    let urlRequest = URLRequest(url: url)
    guard let (imageData, _) = try? await URLSession.shared.data(for: urlRequest) else { return nil }
    
    return UIImage(data: imageData)
}
