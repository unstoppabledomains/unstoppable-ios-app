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
    
    private var wallet: WalletEntity!
    private var router: HomeTabRouter!
    private var userProfilesService: TestableUserProfilesService!
    private var domainProfilesService: TestableDomainProfilesService!
    private var viewModel: HomeExploreViewModel!
    private var recentProfilesStorage: MockRecentGlobalSearchProfilesStorage!
    
    override func setUp() async throws {
        
        domainProfilesService = TestableDomainProfilesService()
        wallet = MockEntitiesFabric.Wallet.mockEntities()[0]
        let profile = MockEntitiesFabric.Profile.createWalletProfile(using: wallet)
        userProfilesService = TestableUserProfilesService(profile: profile)
        router = await MockEntitiesFabric.Home.createHomeTabRouterUsing(profile: profile,
                                                                        userProfilesService: userProfilesService)
        recentProfilesStorage = MockRecentGlobalSearchProfilesStorage()
        viewModel = await HomeExploreViewModel(router: router,
                                               userProfilesService: userProfilesService,
                                               domainProfilesService: domainProfilesService,
                                               recentProfilesStorage: recentProfilesStorage)
        await waitForRequestMade()
    }
}

// MARK: - Recent search
extension HomeExploreViewModelTests {
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

// MARK: - Wallet profile info
extension HomeExploreViewModelTests {
    @MainActor
    func testProfileDisplayInfoUpdatedFromService() async {
        let emptyProfile = createEmptyWalletDomainProfileDetails()
        await publishProfile(emptyProfile)
        XCTAssertNil(viewModel.selectedPublicDomainProfile)
        XCTAssertTrue(viewModel.getProfilesListForSelectedRelationshipType.isEmpty)
        
        let profileName = "domain.x"
        let followersList = ["follower.x", "follower2.x"]
        await createAndPublishWalletDomainProfile(profileName,
                                                  followersList: followersList,
                                                  followingList: followersList)
        
        XCTAssertEqual(viewModel.selectedPublicDomainProfile?.domainName, profileName)
        XCTAssertEqual(viewModel.getProfilesListForSelectedRelationshipType, followersList)
    }
    
    @MainActor
    func testViewModelReturnRightFollowersList() async {
        let followersList = ["follower.x"]
        let followingList = ["follower2.x"]
        await createAndPublishWalletDomainProfile(followersList: followersList,
                                                  followingList: followingList)
        
        viewModel.relationshipType = .followers
        XCTAssertEqual(viewModel.getProfilesListForSelectedRelationshipType, followersList)
        
        viewModel.relationshipType = .following
        XCTAssertEqual(viewModel.getProfilesListForSelectedRelationshipType, followingList)
    }
    
    @MainActor
    func testFollowersScrollingCallLoadMore() async {
        var followersList = [String]()
        
        for i in 0..<HomeExploreViewModel.Constants.numberOfFollowersBeforeLoadMore + 1 {
            let follower = "\(i).x"
            followersList.append(follower)
        }
        await createAndPublishWalletDomainProfile(followersList: followersList,
                                                  followingList: followersList)
        domainProfilesService.loadMoreCallsHistory.removeAll()
        
        viewModel.willDisplayFollower(domainName: followersList[0])
        XCTAssertTrue(domainProfilesService.loadMoreCallsHistory.isEmpty)
        
        viewModel.willDisplayFollower(domainName: followersList[1])
        XCTAssertEqual(domainProfilesService.loadMoreCallsHistory, [viewModel.relationshipType])
        
    }
}

// MARK: - Suggested profiles
extension HomeExploreViewModelTests {
    @MainActor
    func testSuggestionsLoadedOnLaunch() {
        XCTAssertEqual(domainProfilesService.loadSuggestionsCallsHistory, [wallet.address])
        XCTAssertEqual(viewModel.suggestedProfiles, domainProfilesService.profilesSuggestions)
    }
    
    @MainActor
    func testSuggestionsInitialFollowingState() {
        for profile in viewModel.suggestedProfiles {
            XCTAssertFalse(profile.isFollowing)
        }
    }
    
    @MainActor
    func testSuggestedProfileFollowStatusUpdatedSuccess() async {
        let suggestedProfile = domainProfilesService.profilesSuggestions[0]
        viewModel.didSelectToFollowDomainName(suggestedProfile.domain)
        await waitForRequestMade()
        XCTAssertTrue(viewModel.suggestedProfiles[0].isFollowing)
    }
    
    @MainActor
    func testSuggestedProfileFollowStatusUpdatedFailure() async {
        let suggestedProfile = domainProfilesService.profilesSuggestions[0]
        domainProfilesService.shouldFail = true
        viewModel.didSelectToFollowDomainName(suggestedProfile.domain)
        await waitForRequestMade()
        XCTAssertFalse(viewModel.suggestedProfiles[0].isFollowing)
    }
    
    @MainActor
    func testSuggestedProfileFollowStatusUpdatedFromProfilesService() async {
        let suggestedProfile = domainProfilesService.profilesSuggestions[0]
        let userDomainName = wallet.rrDomain!.name
        let followAction = DomainProfileFollowActionDetails(userDomainName: userDomainName,
                                                            targetDomainName: suggestedProfile.domain,
                                                            isFollowing: true)
        domainProfilesService.followActionsPublisher.send(followAction)
        await waitForRequestMade()
        XCTAssertTrue(viewModel.suggestedProfiles[0].isFollowing)
        
        let unfollowAction = DomainProfileFollowActionDetails(userDomainName: userDomainName,
                                                              targetDomainName: suggestedProfile.domain,
                                                              isFollowing: false)
        domainProfilesService.followActionsPublisher.send(unfollowAction)
        await waitForRequestMade()
        XCTAssertFalse(viewModel.suggestedProfiles[0].isFollowing)
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
    
    func createEmptyWalletDomainProfileDetails() -> WalletDomainProfileDetails {
        WalletDomainProfileDetails(walletAddress: "0x1")
    }
    
    @discardableResult
    func createAndPublishWalletDomainProfile(_ domainName: String = "domain.x",
                                                        followersList: [String] = [],
                                                        followingList: [String] = []) async -> WalletDomainProfileDetails {
        let profileName = domainName
        let serializedProfile = MockEntitiesFabric.DomainProfile.createPublicProfile(domain: profileName)
        let displayInfo = DomainProfileDisplayInfo(serializedProfile: serializedProfile)
        var profile = WalletDomainProfileDetails(walletAddress: "0x1",
                                                 profileDomainName: profileName,
                                                 displayInfo: displayInfo)
        updateProfile(&profile,
                      withFollowers: followersList,
                      relationshipType: .followers)
        updateProfile(&profile,
                      withFollowers: followingList,
                      relationshipType: .following)
        await publishProfile(profile)
        
        return profile
    }
    
    func updateProfile(_ profile: inout WalletDomainProfileDetails,
                       withFollowers followersList: [String],
                       relationshipType: DomainProfileFollowerRelationshipType = .followers) {
        let count = followersList.count
        let followersResponse = DomainProfileFollowersResponse(domain: profile.walletAddress,
                                                               data: followersList.map { .init(domain: $0) },
                                                               relationshipType: relationshipType,
                                                               meta: .init(totalCount: count,
                                                                           pagination: .init(cursor: count,
                                                                                             take: count)))
        profile.socialDetails?.applyDetailsFrom(response: followersResponse)
    }
    
    func publishProfile(_ profile: WalletDomainProfileDetails) async {
        domainProfilesService.publisher.send(profile)
        await Task.sleep(seconds: 0.6)
    }
    
    func waitForRequestMade() async {
        await Task.sleep(seconds: 0.1)
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
