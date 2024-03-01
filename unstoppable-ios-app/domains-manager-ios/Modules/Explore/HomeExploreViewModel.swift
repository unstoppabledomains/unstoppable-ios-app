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
    @Published private(set) var trendingProfiles: [HomeExplore.TrendingProfile] = []
    @Published private(set) var isLoadingGlobalProfiles = false
    @Published private var currentTask: SearchProfilesTask?
    @Published var searchDomainsType: HomeExplore.SearchDomainsType = .global
    @Published var relationshipType: DomainProfileFollowerRelationshipType = .following
    @Published var searchKey: String = ""
    @Published var error: Error?
    @Published var isSearchActive: Bool = false

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
            self?.didSearchDomains()
        }.store(in: &cancellables)
//        $isSearchActive.sink { [weak self] isActive in
//            if !isActive {
//                self?.didStopSearch()
//            }
//        }.store(in: &cancellables)
        
        loadAndShowData()
    }
}

// MARK: - Open methods
extension HomeExploreViewModel {
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
                                           dismissCallback: nil)
        }
    }
    
    func didTapTrendingProfile(_ profile: HomeExplore.TrendingProfile) {
        openPublicDomainProfile(domainName: profile.domainName, walletAddress: profile.walletAddress)
    }
}

// MARK: - Private methods
private extension HomeExploreViewModel {
    func loadAndShowData() {
        loadTrendingProfiles()
        if case .wallet(let wallet) = selectedProfile {
            loadFollowersFor(wallet: wallet)
        }
    }
    
    func loadFollowersFor(wallet: WalletEntity) {
        followersList = MockEntitiesFabric.Explore.createFollowersProfiles()
        followingsList = MockEntitiesFabric.Explore.createFollowersProfiles()
    }
    
    func loadTrendingProfiles() {
        trendingProfiles = MockEntitiesFabric.Explore.createTrendingProfiles()
    }
    
    func openPublicDomainProfile(domainName: String, walletAddress: String) {
        guard let selectedWallet = walletsDataService.selectedWallet else { return }
        
        let domainPublicInfo = PublicDomainDisplayInfo(walletAddress: walletAddress, name: domainName)
        router.showPublicDomainProfile(of: domainPublicInfo, by: selectedWallet, preRequestedAction: nil)
    }
}

// MARK: - Search methods
private extension HomeExploreViewModel {
    func didSearchDomains() {
        if searchKey.isEmpty {
            domainsToShow = userDomains
        } else {
            domainsToShow = userDomains.filter({ $0.name.lowercased().contains(getLowercasedTrimmedSearchKey()) })
        }
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
                let profiles = try await searchForGlobalProfiles(with: getLowercasedTrimmedSearchKey())
                let userDomains = Set(self.userDomains.map({ $0.name }))
                self.globalProfiles = profiles.filter({ !userDomains.contains($0.name) && $0.ownerAddress != nil })
            }
            isLoadingGlobalProfiles = false
        }
    }
    
    func searchForGlobalProfiles(with searchKey: String) async throws -> [SearchDomainProfile] {
        // Cancel previous search task if it exists
        currentTask?.cancel()
        
        let task: SearchProfilesTask = Task.detached {
            do {
                try Task.checkCancellation()
                
                let profiles = try await self.searchForDomains(searchKey: searchKey)
                
                try Task.checkCancellation()
                return profiles
            } catch NetworkLayerError.requestCancelled, is CancellationError {
                return []
            } catch {
                throw error
            }
        }
        
        currentTask = task
        let users = try await task.value
        return users
    }
    
    func searchForDomains(searchKey: String) async throws -> [SearchDomainProfile] {
        if searchKey.isValidAddress() {
            let wallet = searchKey
            if let domain = try? await loadGlobalDomainRRInfo(for: wallet) {
                return [domain]
            }
            
            return []
        } else {
            let domains = try await NetworkService().searchForDomainsWith(name: searchKey, shouldBeSetAsRR: false)
            return domains
        }
    }
    
    func loadGlobalDomainRRInfo(for key: String) async throws -> SearchDomainProfile? {
        if let rrInfo = try? await NetworkService().fetchGlobalReverseResolution(for: key.lowercased()),
           rrInfo.name.isUDTLD() {
            
            return SearchDomainProfile(name: rrInfo.name,
                                       ownerAddress: rrInfo.address,
                                       imagePath: rrInfo.pfpURLToUse?.absoluteString,
                                       imageType: .offChain)
        }
        
        return nil
    }
}
