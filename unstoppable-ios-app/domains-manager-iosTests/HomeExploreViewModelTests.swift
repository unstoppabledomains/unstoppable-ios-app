//
//  HomeExploreViewModelTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 06.03.2024.
//

import XCTest
@testable import domains_manager_ios
import Combine

final class HomeExploreViewModelTests: BaseTestClass {
    
    
    private var router: HomeTabRouter!
    private var viewModel: HomeExploreViewModel!
    private var recentProfilesStorage: MockRecentGlobalSearchProfilesStorage!
    
    override func setUp() async throws {
        router = await MockEntitiesFabric.Home.createHomeTabRouter(isWebProfile: false)
        recentProfilesStorage = MockRecentGlobalSearchProfilesStorage()
        viewModel = await HomeExploreViewModel(router: router,
                                               recentProfilesStorage: recentProfilesStorage)
    }
    
    @MainActor
    func testViewModelTakeRecentProfilesFromStorageOnLaunch() {
        XCTAssertEqual([], viewModel.recentProfiles)

        let profiles: [SearchDomainProfile] = [createSearchDomainProfileWithName("domain.x"),
                                               createSearchDomainProfileWithName("domain2.x")]
        recentProfilesStorage.profiles = profiles
        viewModel = HomeExploreViewModel(router: router,
                                         recentProfilesStorage: recentProfilesStorage)
        
        XCTAssertEqual(profiles, viewModel.recentProfiles)
    }
    
    @MainActor
    func testViewModelAddRecentProfile() {
        let profile = createSearchDomainProfileWithName()
        viewModel.didTapSearchDomainProfile(profile)
        XCTAssertEqual([profile], viewModel.recentProfiles)
    }
    
    @MainActor
    func testViewModelAddRecentProfilesToStorage() {
        let profile = createSearchDomainProfileWithName()
        viewModel.didTapSearchDomainProfile(profile)
        XCTAssertEqual([profile], recentProfilesStorage.profiles)
    }

    @MainActor
    func testViewModelClearRecentProfiles() {
        viewModel.didTapSearchDomainProfile(createSearchDomainProfileWithName())
        viewModel.clearRecentSearchButtonPressed()
        XCTAssertTrue(viewModel.recentProfiles.isEmpty)
    }
    
    @MainActor
    func testViewModelClearRecentProfilesFromStorage() {
        recentProfilesStorage.profiles = [createSearchDomainProfileWithName()]
        viewModel.clearRecentSearchButtonPressed()
        XCTAssertTrue(recentProfilesStorage.profiles.isEmpty)
    }
}

// MARK: - Private methods
private extension HomeExploreViewModelTests {
    func createSearchDomainProfileWithName(_ name: String = "domain.x") -> SearchDomainProfile {
        SearchDomainProfile(name: name,
                            ownerAddress: "0x1",
                            imagePath: nil,
                            imageType: nil)
    }
}

private final class MockRecentGlobalSearchProfilesStorage: RecentGlobalSearchProfilesStorageProtocol {
    
    var profiles = [SearchDomainProfile]()
    
    func getRecentProfiles() -> [SearchDomainProfile] {
        profiles
    }
    
    func addProfileToRecent(_ profile: SearchDomainProfile) {
        profiles.append(profile)
    }
    
    func clearRecentProfiles() {
        profiles.removeAll()
    }
}
