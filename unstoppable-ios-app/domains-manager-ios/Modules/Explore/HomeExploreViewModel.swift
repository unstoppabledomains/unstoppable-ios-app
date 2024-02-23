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
    
    @Published private var currentTask: SearchProfilesTask?
    @Published private var globalProfiles: [SearchDomainProfile] = []
    @Published private var userDomains: [DomainDisplayInfo] = []
    @Published private var domainsToShow: [DomainDisplayInfo] = []
    @Published private var isLoadingGlobalProfiles = false
    @Published var searchKey: String = ""
    @Published var error: Error?
    @Published var isSearchActive: Bool = false
    @Published private(set) var selectedProfile: UserProfile

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
    
        $searchKey.sink { [weak self] searchText in
//            self?.didSearchWith(key: searchText)
        }.store(in: &cancellables)
        $isSearchActive.sink { [weak self] isActive in
            if !isActive {
//                self?.didStopSearch()
            }
        }.store(in: &cancellables)
        
//        loadAndShowData()
    }
}
