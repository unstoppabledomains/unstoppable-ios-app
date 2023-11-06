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
        private(set) var viewingDomain: DomainItem
        @Published var records: [CryptoRecord]?
        @Published var socialInfo: DomainProfileSocialInfo?
        @Published var socialAccounts: SocialAccounts?
        @Published var error: Error?
        @Published private(set) var isLoading = false
        @Published private(set) var isUDBlue = false
        @Published private(set) var isUserDomainSelected = true
        @Published private(set) var profile: SerializedPublicDomainProfile?
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
             viewingDomain: DomainItem,
             preRequestedAction: PreRequestedProfileAction?,
             delegate: PublicProfileViewDelegate?) {
            self.domain = domain
            self.viewingDomain = viewingDomain
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
        
        func didSelectViewingDomain(_ domain: DomainDisplayInfo) {
            Task {
                guard let domainItem = try? await appContext.dataAggregatorService.getDomainWith(name: domain.name) else {
                    error = PublicProfileError.failedToFindDomain
                    return
                }
                viewingDomainImage = nil
                isFollowing = nil
                loadFollowingState()
                viewingDomain = domainItem
                loadViewingDomainData()
            }
        }
        
        private func loadAllProfileData() {
            loadPublicProfile()
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
                    let domains = await appContext.dataAggregatorService.getDomainsDisplayInfo()
                    await waitForAppear()
                    self.profile = profile
                    isUserDomainSelected = domains.first(where: { $0.name == domain.name }) != nil
                    records = await convertRecordsFrom(recordsDict: profile.records ?? [:])
                    socialInfo = profile.social
                    socialAccounts = profile.socialAccounts
                    isUDBlue = profile.profile.udBlue ?? false
                    isLoading = false
                    loadImages()
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
                if let imagePath = profile?.profile.imagePath,
                   let url = URL(string: imagePath) {
                    let avatarImage = await appContext.imageLoadingService.loadImage(from: .url(url),
                                                                                     downsampleDescription: .mid)
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
                                                                                    downsampleDescription: .mid)
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
                try? await Task.sleep(seconds: dif)
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

extension PublicDomainProfileAttributes {
    static let empty = PublicDomainProfileAttributes(displayName: nil,
                                                     description: nil,
                                                     location: nil,
                                                     web2Url: nil,
                                                     imagePath: nil,
                                                     imageType: nil,
                                                     coverPath: nil,
                                                     phoneNumber: nil,
                                                     domainPurchased: nil,
                                                     udBlue: false)
    
    static let filled = PublicDomainProfileAttributes(displayName: "Oleg Kuplin",
                                                      description: "Unstoppable iOS developer",
                                                      location: "Danang",
                                                      web2Url: "ud.me/oleg.x",
                                                      imagePath: "nil",
                                                      imageType: .onChain,
                                                      coverPath: "nil",
                                                      phoneNumber: nil,
                                                      domainPurchased: nil,
                                                      udBlue: false)
}

func loadImageFrom(url: URL) async -> UIImage? {
    let urlRequest = URLRequest(url: url)
    guard let (imageData, _) = try? await URLSession.shared.data(for: urlRequest) else { return nil }
    
    return UIImage(data: imageData)
}
