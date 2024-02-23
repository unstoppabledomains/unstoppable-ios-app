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
    
    typealias SearchProfilesTask = Task<[SearchDomainProfile], Error>

    var analyticsName: Analytics.ViewName { .homeExplore }
    
    @Published private(set) var selectedProfile: UserProfile
    @Published private(set) var followersList: [SerializedPublicDomainProfile] = []
    @Published private(set) var followingsList: [SerializedPublicDomainProfile] = []
    @Published private(set) var globalProfiles: [SearchDomainProfile] = []
    @Published private(set) var userDomains: [DomainDisplayInfo] = []
    @Published private(set) var domainsToShow: [DomainDisplayInfo] = []
    @Published private(set) var isLoadingGlobalProfiles = false
    @Published private var currentTask: SearchProfilesTask?
    @Published var searchKey: String = ""
    @Published var error: Error?
    @Published var isSearchActive: Bool = false
    @Published var expandedFollowerTypes: Set<DomainProfileFollowerRelationshipType> = []

    private var router: HomeTabRouter
    private var cancellables: Set<AnyCancellable> = []
    private let walletsDataService: WalletsDataServiceProtocol

    init(router: HomeTabRouter,
         walletsDataService: WalletsDataServiceProtocol = appContext.walletsDataService) {
        self.selectedProfile = router.profile
        self.router = router
        self.walletsDataService = walletsDataService
        userDomains = walletsDataService.wallets.combinedDomains().sorted(by: { $0.name < $1.name })
        domainsToShow = userDomains
        appContext.userProfileService.selectedProfilePublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedProfile in
            if let selectedProfile {
                self?.selectedProfile = selectedProfile
            }
        }.store(in: &cancellables)
    
        $searchKey.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main).sink { [weak self] searchText in
//            self?.didSearchWith(key: searchText)
        }.store(in: &cancellables)
        $isSearchActive.sink { [weak self] isActive in
            if !isActive {
//                self?.didStopSearch()
            }
        }.store(in: &cancellables)
        
        loadAndShowData()
    }
}

// MARK: - Private methods
private extension HomeExploreViewModel {
    func loadAndShowData() {
        if case .wallet(let wallet) = selectedProfile {
            loadFollowersFor(wallet: wallet)
        }
    }
    
    func loadFollowersFor(wallet: WalletEntity) {
        followersList = MockEntitiesFabric.Explore.createFollowersProfiles()
        followingsList = MockEntitiesFabric.Explore.createFollowersProfiles()
    }
    
}
