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
    @Published private(set) var recentProfiles: [HomeExplore.ExploreDomainProfile] = []
    @Published private(set) var isLoadingGlobalProfiles = false
    @Published private(set) var userWalletNonEmptySearchResults: [HomeExplore.UserWalletNonEmptySearchResult] = []
    @Published var userWalletCollapsedAddresses: Set<String> = []
    
    @Published var searchDomainsType: HomeExplore.SearchDomainsType = .global
    @Published var relationshipType: DomainProfileFollowerRelationshipType = .following
    @Published var searchKey: String = ""
    @Published var error: Error?
    @Published var isKeyboardActive: Bool = true
    var isSearchActive: Bool { isKeyboardActive || !searchKey.isEmpty }

    private var router: HomeTabRouter
    private var cancellables: Set<AnyCancellable> = []
    @Published private var relationshipDetails: WalletDomainProfileDetails?
    private var socialRelationshipDetailsPublisher: AnyCancellable?
    private let walletsDataService: WalletsDataServiceProtocol
    private let searchService = DomainsGlobalSearchService()
    
    init(router: HomeTabRouter,
         walletsDataService: WalletsDataServiceProtocol = appContext.walletsDataService) {
        self.selectedProfile = router.profile
        self.router = router
        self.walletsDataService = walletsDataService
        userDomains = walletsDataService.wallets.combinedDomains().sorted(by: { $0.name < $1.name })
        appContext.userProfileService.selectedProfilePublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedProfile in
            self?.setSelectedProfile(selectedProfile)
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
        relationshipDetails?.socialDetails?.getFollowersListFor(relationshipType: self.relationshipType) ?? []
    }
    
    var selectedPublicDomainProfile: DomainProfileDisplayInfo? {
        relationshipDetails?.displayInfo
    }
    
    func didTapSearchDomainProfile(_ profile: SearchDomainProfile) {
        guard let walletAddress = profile.ownerAddress else { return }
        
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
        
        if index + 6 >= followersList.count {
            appContext.domainProfilesService.loadMoreSocialIfAbleFor(relationshipType: self.relationshipType,
                                                                     in: wallet)
        }
    }
 
    func clearRecentSearchButtonPressed() {
        
    }
}

// MARK: - Private methods
private extension HomeExploreViewModel {
    func loadAndShowData() {
        loadTrendingProfiles()
        loadRecentProfiles()
        setUserWalletSearchResults()
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
        recentProfiles = MockEntitiesFabric.Explore.createTrendingProfiles()
    }
    
    func setUserWalletSearchResults() {
        let userWallets = walletsDataService.wallets
        userWalletNonEmptySearchResults = userWallets.compactMap({ .init(wallet: $0, searchKey: getLowercasedTrimmedSearchKey()) })
    }
    
    func setSelectedProfile(_ selectedProfile: UserProfile?) {
        if let selectedProfile {
            self.selectedProfile = selectedProfile
        }
        if case .wallet(let wallet) = selectedProfile {
            Task {
                socialRelationshipDetailsPublisher = await appContext.domainProfilesService.publisherForWalletDomainProfileDetails(wallet: wallet).receive(on: DispatchQueue.main).sink { [weak self] relationshipDetails in
                    self?.relationshipDetails = relationshipDetails
                }
            }
        } else {
            socialRelationshipDetailsPublisher = nil
        }
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
