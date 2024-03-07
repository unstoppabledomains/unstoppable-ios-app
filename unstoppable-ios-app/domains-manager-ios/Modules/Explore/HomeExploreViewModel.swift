//
//  HomeExploreViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.02.2024.
//

import SwiftUI
import Combine

@MainActor
final class HomeExploreViewModel: ObservableObject, ViewAnalyticsLogger {
    
    var analyticsName: Analytics.ViewName { .homeExplore }
    
    @Published private(set) var selectedProfile: UserProfile
    @Published private(set) var globalProfiles: [SearchDomainProfile] = []
    @Published private(set) var userDomains: [DomainDisplayInfo] = []
    @Published private(set) var trendingProfiles: [HomeExplore.ExploreDomainProfile] = []
    @Published private(set) var recentProfiles: [SearchDomainProfile] = []
    @Published private(set) var suggestedProfiles: [DomainProfileSuggestion] = []
    @Published private(set) var isLoadingGlobalProfiles = false
    @Published private(set) var userWalletNonEmptySearchResults: [HomeExplore.UserWalletNonEmptySearchResult] = []
    @Published var userWalletCollapsedAddresses: Set<String> = []
    
    @Published var searchDomainsType: HomeExplore.SearchDomainsType = .global
    @Published var relationshipType: DomainProfileFollowerRelationshipType = .following
    @Published var searchKey: String = ""
    @Published var error: Error?
    @Published var isKeyboardActive: Bool = false
    var isSearchActive: Bool { isKeyboardActive || !searchKey.isEmpty }

    let router: HomeTabRouter
    private var cancellables: Set<AnyCancellable> = []
    @Published private var walletDomainProfileDetails: WalletDomainProfileDetails?
    private var socialRelationshipDetailsPublisher: AnyCancellable?
    private let walletsDataService: WalletsDataServiceProtocol
    private let domainProfilesService: DomainProfilesServiceProtocol
    private let searchService = DomainsGlobalSearchService()
    private let recentProfilesStorage: RecentGlobalSearchProfilesStorageProtocol
    
    init(router: HomeTabRouter,
         walletsDataService: WalletsDataServiceProtocol = appContext.walletsDataService,
         domainProfilesService: DomainProfilesServiceProtocol = appContext.domainProfilesService,
         recentProfilesStorage: RecentGlobalSearchProfilesStorageProtocol = HomeExplore.RecentGlobalSearchProfilesStorage.instance) {
        self.selectedProfile = router.profile
        self.router = router
        self.walletsDataService = walletsDataService
        self.domainProfilesService = domainProfilesService
        self.recentProfilesStorage = recentProfilesStorage
        userDomains = walletsDataService.wallets.combinedDomains().sorted(by: { $0.name < $1.name })
        appContext.userProfileService.selectedProfilePublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedProfile in
            if let selectedProfile {
                self?.selectedProfile = selectedProfile
                self?.didUpdateSelectedProfile()
            }
        }.store(in: &cancellables)
    
        $searchKey.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main).sink { [weak self] searchText in
            self?.didSearchDomains()
        }.store(in: &cancellables)
        
        loadAndShowData()
    }
}

// MARK: - Open methods
extension HomeExploreViewModel {
    var getProfilesListForSelectedRelationshipType: [DomainName] {
        walletDomainProfileDetails?.socialDetails?.getFollowersListFor(relationshipType: self.relationshipType) ?? []
    }
    
    var selectedPublicDomainProfile: DomainProfileDisplayInfo? {
        walletDomainProfileDetails?.displayInfo
    }
    
    func didTapSearchDomainProfile(_ profile: SearchDomainProfile) {
        guard let walletAddress = profile.ownerAddress else { return }
        
        makeChangesToRecentProfilesStorage { storage in
            storage.addProfileToRecent(profile)
        }
        openPublicDomainProfile(domainName: profile.name, walletAddress: walletAddress)
    }
    
    func didTapUserDomainProfile(_ domain: DomainDisplayInfo) {
        guard let wallet = walletsDataService.wallets.findOwningDomain(domain.name) else { return }
        
        Task {
            await router.showDomainProfile(domain,
                                           wallet: wallet,
                                           preRequestedAction: nil,
                                           shouldResetNavigation: false,
                                           dismissCallback: nil)
        }
    }
    
    func didTapUserPublicDomainProfileDisplayInfo(_ profile: DomainProfileDisplayInfo) {
        openPublicDomainProfile(domainName: profile.domainName, walletAddress: profile.ownerWallet)
    }
    
    func didTapTrendingProfile(_ profile: HomeExplore.ExploreDomainProfile) {
        openPublicDomainProfile(domainName: profile.domainName, walletAddress: profile.walletAddress)
    }
  
    func willDisplayFollower(domainName: DomainName) {
        let followersList = getProfilesListForSelectedRelationshipType
        guard let index = followersList.firstIndex(of: domainName),
            case .wallet(let wallet) = selectedProfile else { return }
        
        if index + Constants.numberOfFollowersBeforeLoadMore >= followersList.count {
            domainProfilesService.loadMoreSocialIfAbleFor(relationshipType: self.relationshipType,
                                                          in: wallet)
        }
    }
 
    func clearRecentSearchButtonPressed() {
        makeChangesToRecentProfilesStorage { storage in
            storage.clearRecentProfiles()
        }
    }
    
    func didSelectActionInEmptyState(_ state: HomeExplore.EmptyState) {
        switch state {
        case .noProfile:
            router.runPurchaseFlow()
        case .noFollowers:
            shareSelectedProfile()
        case .noFollowing:
            showSuggestedPeopleList()
        }
    }
    
    func didSelectDomainProfileSuggestion(_ profileSuggestion: DomainProfileSuggestion) {
        openPublicDomainProfile(domainName: profileSuggestion.domain,
                                walletAddress: profileSuggestion.address)
    }
    
    func didSelectToFollowDomainName(_ domainName: DomainName) {
        followBySelectedProfile(domainName: domainName)
    }
}

// MARK: - Private methods
private extension HomeExploreViewModel {
    func loadAndShowData() {
        loadTrendingProfiles()
        loadRecentProfiles()
        setUserWalletSearchResults()
        updateWalletDomainProfileDetailsForSelectedProfile()
        loadSuggestedProfiles()
    }
    
    func loadTrendingProfiles() {
        trendingProfiles = MockEntitiesFabric.Explore.createTrendingProfiles()
    }
    
    func openPublicDomainProfile(domainName: String, walletAddress: String) {
        guard let selectedWallet = walletsDataService.selectedWallet else { return }
        
        let domainPublicInfo = PublicDomainDisplayInfo(walletAddress: walletAddress, name: domainName)
        router.showPublicDomainProfile(of: domainPublicInfo, by: selectedWallet, preRequestedAction: nil)
    }
    
    func loadRecentProfiles() {
        recentProfiles = recentProfilesStorage.getRecentProfiles()
    }
    
    func setUserWalletSearchResults() {
        let userWallets = walletsDataService.wallets
        userWalletNonEmptySearchResults = userWallets.compactMap({ .init(wallet: $0, searchKey: getLowercasedTrimmedSearchKey()) })
    }
    
    func didUpdateSelectedProfile() {
        updateWalletDomainProfileDetailsForSelectedProfile()
    }
    
    func updateWalletDomainProfileDetailsForSelectedProfile() {
        if case .wallet(let wallet) = selectedProfile {
            Task {
                socialRelationshipDetailsPublisher = await domainProfilesService.publisherForWalletDomainProfileDetails(wallet: wallet).receive(on: DispatchQueue.main).sink { [weak self] relationshipDetails in
                    self?.walletDomainProfileDetails = relationshipDetails
                }
            }
        } else {
            socialRelationshipDetailsPublisher = nil
        }
    }
    
    func makeChangesToRecentProfilesStorage(_ block: (RecentGlobalSearchProfilesStorageProtocol)->()) {
        block(recentProfilesStorage)
        loadRecentProfiles()
    }
    
    func loadSuggestedProfiles() {
        let suggestedProfiles = MockEntitiesFabric.ProfileSuggestions.createSuggestionsForPreview()
        setSuggestedProfiles(suggestedProfiles)
    }
}

// MARK: - Private methods
private extension HomeExploreViewModel {
    func shareSelectedProfile() {
        guard let selectedPublicDomainProfile,
            let topVC = appContext.coreAppCoordinator.topVC else { return }
        
        topVC.shareDomainProfile(domainName: selectedPublicDomainProfile.domainName, isUserDomain: true)
    }
    
    func showSuggestedPeopleList() {
        router.exploreTabNavPath.append(.suggestionsList)
    }
    
    func setSuggestedProfiles(_ suggestedProfiles: [DomainProfileSuggestion]) {
        withAnimation {
            self.suggestedProfiles = suggestedProfiles
        }
    }
    
    func markSuggestedProfileWith(domainName: DomainName,
                                  asFollowing isFollowing: Bool) {
        if let i = suggestedProfiles.firstIndex(where: { $0.domain == domainName }) {
            withAnimation {
                suggestedProfiles[i].isFollowing = isFollowing
            }
        }
    }
    
    func followBySelectedProfile(domainName: DomainName) {
        guard let rrDomain = getSelectedUserProfileRRDomain() else { return }
        
        Task {
            do {
                markSuggestedProfileWith(domainName: domainName, asFollowing: true)
                try await domainProfilesService.followProfileWith(domainName: domainName,
                                                                  by: rrDomain)
            } catch {
                self.error = error
                markSuggestedProfileWith(domainName: domainName, asFollowing: false)
            }
        }
    }
    
    func getSelectedUserProfileRRDomain() -> DomainDisplayInfo? {
        guard case .wallet(let wallet) = selectedProfile else { return nil }
        
        return wallet.rrDomain
    }
}

// MARK: - Search methods
private extension HomeExploreViewModel {
    func didSearchDomains() {
        setUserWalletSearchResults()
        globalProfiles.removeAll()
        scheduleSearchGlobalProfiles()
    }
    
    func getLowercasedTrimmedSearchKey() -> String {
        searchKey.trimmedSpaces.lowercased()
    }
    
    func scheduleSearchGlobalProfiles() {
        isLoadingGlobalProfiles = true
        Task {
            do {
                let profiles = try await searchService.searchForGlobalProfiles(with: getLowercasedTrimmedSearchKey())
                let userDomains = Set(self.userDomains.map({ $0.name }))
                self.globalProfiles = profiles.filter({ !userDomains.contains($0.name) && $0.ownerAddress != nil })
            }
            isLoadingGlobalProfiles = false
        }
    }
}

// MARK: - Open methods
extension HomeExploreViewModel {
    struct Constants {
        static let numberOfFollowersBeforeLoadMore = 6
    }
}
