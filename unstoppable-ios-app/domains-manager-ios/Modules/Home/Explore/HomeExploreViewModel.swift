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
    
    @Published private(set) var globalProfiles: [SearchDomainProfile] = []
    @Published private(set) var userDomains: [DomainDisplayInfo] = []
    @Published private(set) var trendingProfiles: [DomainName] = []
    @Published private(set) var recentProfiles: [SearchDomainProfile] = []
    @Published private(set) var suggestedProfiles: [DomainProfileSuggestion] = []
    @Published private(set) var isLoadingGlobalProfiles = false
    @Published private(set) var userWalletNonEmptySearchResults: [HomeExplore.UserWalletNonEmptySearchResult] = []
    @Published private var walletDomainProfileDetails: WalletDomainProfileDetails?
    
    @Published var userWalletCollapsedAddresses: Set<String> = []
    @Published var relationshipType: DomainProfileFollowerRelationshipType = .following
    @Published var searchDomainsType: HomeExplore.SearchDomainsType = .global
    @Published var searchKey: String = ""
    @Published var isKeyboardActive: Bool = false
    @Published var error: Error?
    
    private let router: HomeTabRouter
    private var selectedProfile: UserProfile
    private var cancellables: Set<AnyCancellable> = []
    private var socialRelationshipDetailsPublisher: AnyCancellable?
    
    private let userProfileService: UserProfileServiceProtocol
    private let walletsDataService: WalletsDataServiceProtocol
    private let domainProfilesService: DomainProfilesServiceProtocol
    private let searchService = DomainsGlobalSearchService()
    private let recentProfilesStorage: RecentGlobalSearchProfilesStorageProtocol
    
    init(router: HomeTabRouter,
         userProfileService: UserProfileServiceProtocol = appContext.userProfileService,
         walletsDataService: WalletsDataServiceProtocol = appContext.walletsDataService,
         domainProfilesService: DomainProfilesServiceProtocol = appContext.domainProfilesService,
         recentProfilesStorage: RecentGlobalSearchProfilesStorageProtocol = HomeExplore.RecentGlobalSearchProfilesStorage.instance) {
        self.selectedProfile = router.profile
        self.router = router
        self.userProfileService = userProfileService
        self.walletsDataService = walletsDataService
        self.domainProfilesService = domainProfilesService
        self.recentProfilesStorage = recentProfilesStorage
        setup()
        loadAndShowData()
    }
}

// MARK: - Open methods
extension HomeExploreViewModel {
    var isSearchActive: Bool { isKeyboardActive || !searchKey.isEmpty }

    var getProfilesListForSelectedRelationshipType: [DomainName] {
        getFollowersFor(relationshipType: self.relationshipType)
    }
    
    private func getFollowersFor(relationshipType: DomainProfileFollowerRelationshipType) -> [DomainName] {
        walletDomainProfileDetails?.socialDetails?.getFollowersListFor(relationshipType: relationshipType) ?? []
    }
    
    var isProfileAvailable: Bool { getSelectedUserProfileRRDomain() != nil }
    
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
    func setup() {
        setDomainsForUserWallet()
        userProfileService.selectedProfilePublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedProfile in
            if let selectedProfile,
               selectedProfile.id != self?.selectedProfile.id {
                self?.selectedProfile = selectedProfile
                self?.didUpdateSelectedProfile()
            }
        }.store(in: &cancellables)
        
        $searchKey.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main).sink { [weak self] searchText in
            self?.didSearchDomains()
        }.store(in: &cancellables)
        
        domainProfilesService.followActionsPublisher.receive(on: DispatchQueue.main).sink { [weak self] actionDetails in
            self?.didReceiveFollowActionDetails(actionDetails)
        }.store(in: &cancellables)
        walletsDataService.walletsPublisher.receive(on: DispatchQueue.main).sink { [weak self] wallets in
            self?.setDomainsForUserWallet()
        }.store(in: &cancellables)
    }
    
    func setDomainsForUserWallet() {
        let domains = walletsDataService.wallets.combinedDomains()
        if domains.count != self.userDomains.count {
            self.userDomains = domains.sorted(by: { $0.name < $1.name })
        }
    }
    
    func loadAndShowData() {
        loadTrendingProfiles()
        loadRecentProfiles()
        setUserWalletSearchResults()
        updateWalletDomainProfileDetailsForSelectedProfile()
        loadSuggestedProfilesIfAvailable()
    }
    
    func loadTrendingProfiles() {
        Task {    
            trendingProfiles = try await domainProfilesService.getTrendingDomainNames()
        }
    }
    
    func openPublicDomainProfile(domainName: String, walletAddress: String) {
        let domainPublicInfo = PublicDomainDisplayInfo(walletAddress: walletAddress, name: domainName)
        router.showPublicDomainProfile(of: domainPublicInfo)
    }
    
    func loadRecentProfiles() {
        recentProfiles = recentProfilesStorage.getRecentProfiles()
    }
    
    func setUserWalletSearchResults() {
        let userWallets = walletsDataService.wallets
        userWalletNonEmptySearchResults = userWallets.compactMap({ .init(wallet: $0, searchKey: getLowercasedTrimmedSearchKey()) })
    }
    
    func didUpdateSelectedProfile() {
        isKeyboardActive = false
        updateWalletDomainProfileDetailsForSelectedProfile()
        reloadSuggestedProfilesIfAvailable()
    }
    
    func updateWalletDomainProfileDetailsForSelectedProfile() {
        walletDomainProfileDetails = nil
        if case .wallet(let wallet) = selectedProfile {
            Task {
                socialRelationshipDetailsPublisher = await domainProfilesService.publisherForWalletDomainProfileDetails(wallet: wallet)
                    .receive(on: DispatchQueue.main)
                    .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                    .sink { [weak self] relationshipDetails in
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
    
    func clearSuggestedProfiles() {
        setSuggestedProfiles([])
    }
    
    func loadSuggestedProfilesIfAvailable() {
        if case .wallet(let wallet) = selectedProfile {
            loadSuggestedProfilesFor(wallet: wallet)
        }
    }
    
    func loadSuggestedProfilesFor(wallet: WalletEntity) {
        guard let rrDomain = getSelectedUserProfileRRDomain() else { return }
        Task {
            let suggestedProfiles = try await domainProfilesService.getSuggestionsFor(domainName: rrDomain.name)
            setSuggestedProfiles(suggestedProfiles)
        }
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
                loadNewProfileSuggestionsIfAllFollowing()
            } catch {
                self.error = error
                markSuggestedProfileWith(domainName: domainName, asFollowing: false)
            }
        }
    }
    
    func getSelectedUserProfileRRDomain() -> DomainDisplayInfo? {
        guard case .wallet(let wallet) = selectedProfile else { return nil }
        
        switch wallet.getCurrentWalletRepresentingDomainState() {
        case .udDomain(let domain), .ensDomain(let domain):
            return domain
        case .noRRDomain:
            return nil
        }
    }
  
    func loadNewProfileSuggestionsIfAllFollowing() {
        if isFollowingAllCurrentlySuggestedProfiles() {
            reloadSuggestedProfilesIfAvailable()
        }
    }
    
    func isFollowingAllCurrentlySuggestedProfiles() -> Bool {
        suggestedProfiles.first(where: { !$0.isFollowing }) == nil
    }
    
    func reloadSuggestedProfilesIfAvailable() {
        clearSuggestedProfiles()
        loadSuggestedProfilesIfAvailable()
    }
    
    func didReceiveFollowActionDetails(_ actionDetails: DomainProfileFollowActionDetails) {
        guard isFollowActionDetailsMadeByCurrentUser(actionDetails) else { return }
        
        markSuggestedProfileWith(domainName: actionDetails.targetDomainName,
                                 asFollowing: actionDetails.isFollowing)
    }
    
    func isFollowActionDetailsMadeByCurrentUser(_ actionDetails: DomainProfileFollowActionDetails) -> Bool {
        actionDetails.userDomainName == getSelectedUserProfileRRDomain()?.name
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
                self.globalProfiles = try await searchService.searchForGlobalProfilesExcludingUsers(with: searchKey,
                                                                                                    walletsDataService: walletsDataService)
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
