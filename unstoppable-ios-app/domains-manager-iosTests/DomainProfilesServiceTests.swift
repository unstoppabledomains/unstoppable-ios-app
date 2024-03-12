//
//  DomainProfilesServiceTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 05.03.2024.
//

import XCTest
@testable import domains_manager_ios
import Combine

final class DomainProfilesServiceTests: BaseTestClass {
    
    private var networkService: MockNetworkService!
    private var storage: MockStorage!
    private var service: DomainProfilesService!
    let mockDomainName = "test.x"
    
    override func setUp() async throws {
        networkService = MockNetworkService()
        storage = MockStorage()
        service = DomainProfilesService(networkService: networkService,
                                        storage: storage,
                                        walletsDataService: appContext.walletsDataService)
    }
    
    // MARK: - Cached Profile Tests
    func test_getCachedPublicDomainProfileDisplayInfo_returnsCachedValue() throws {
        let mockProfile = createMockDomainProfileAndStoreInCache()
        let cachedProfile = service.getCachedDomainProfileDisplayInfo(for: mockDomainName)
        
        XCTAssertEqual(cachedProfile, mockProfile)
    }
    
    func test_getCachedPublicDomainProfileDisplayInfo_returnsNilForMissingCache() {
        let cachedProfile = service.getCachedDomainProfileDisplayInfo(for: mockDomainName)
        
        XCTAssertNil(cachedProfile)
    }
    
    // MARK: - Profile Stream Tests
    func test_getCachedAndRefreshProfileStream_yieldsCachedProfileThenRefreshed() async throws {
        let cachedProfile = createMockDomainProfileAndStoreInCache()
        let refreshedSerializedProfile = MockEntitiesFabric.DomainProfile.createPublicProfile(domain: mockDomainName)
        networkService.profileToReturn = refreshedSerializedProfile
        let refreshedPublicProfile = DomainProfileDisplayInfo(serializedProfile: refreshedSerializedProfile)
        
        let stream = service.getCachedAndRefreshDomainProfileStream(for: mockDomainName)
        
        var receivedValues: [DomainProfileDisplayInfo] = []
        do {
            for try await value in stream {
                receivedValues.append(value)
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        XCTAssertEqual(receivedValues, [cachedProfile, refreshedPublicProfile])
    }
    
    func test_getCachedAndRefreshProfileStream_yieldsOnlyRefreshedProfileIfNoCache() async throws {
        let refreshedSerializedProfile = MockEntitiesFabric.DomainProfile.createPublicProfile(domain: mockDomainName)
        networkService.profileToReturn = refreshedSerializedProfile
        let refreshedPublicProfile = DomainProfileDisplayInfo(serializedProfile: refreshedSerializedProfile)
        
        let stream = service.getCachedAndRefreshDomainProfileStream(for: mockDomainName)
        
        var receivedValues: [DomainProfileDisplayInfo] = []
        do {
            for try await value in stream {
                receivedValues.append(value)
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues[0], refreshedPublicProfile)
    }
    
    func test_getCachedAndRefreshProfileStream_throwsErrorOnNetworkError() async throws {
        networkService.shouldFail = true
        let stream = service.getCachedAndRefreshDomainProfileStream(for: mockDomainName)
        
        do {
            for try await _ in stream {
                XCTFail("Expected network error to be thrown")
            }
        } catch {
            assertNetworkErrorThrown(error)
        }
    }
    
    // MARK: - Follow Function Tests
    func testFollowNetwork_Success() async throws {
        try await service.followProfileWith(domainName: mockDomainName, by: mockDomainDisplayInfo())
        XCTAssertEqual(networkService.followCallDomainNames, [mockDomainName])
    }
    
    func testResetDataResetAfterFollow_Success() async throws {
        try await ensureFollowersResetAfterAsyncFunction {
            try await service.followProfileWith(domainName: mockDomainName, by: mockDomainDisplayInfo())
        }
    }
    
    func testFollowNetwork_NetworkFailure() async throws {
        networkService.shouldFail = true
        do {
            try await service.followProfileWith(domainName: mockDomainName, by: mockDomainDisplayInfo())
            XCTFail("Expected network error")
        } catch {
            assertNetworkErrorThrown(error)
        }
    }
    
    func testFollowActionSend_Success() async throws {
        let domain = mockDomainDisplayInfo()
        let action = DomainProfileFollowActionDetails(userDomainName: domain.name,
                                                      targetDomainName: mockDomainName,
                                                      isFollowing: true)
        try await ensureFollowingActionSend(action: action, by: domain)
    }
    
    func testFollowActionSend_Failure() async throws {
        networkService.shouldFail = true
        let receiver = CombineValuesCapturer(passthroughSubject: service.followActionsPublisher)
        try? await service.followProfileWith(domainName: mockDomainName, by: mockDomainDisplayInfo())
        
        XCTAssertTrue(receiver.capturedValues.isEmpty)
    }
    
    // MARK: - Unfollow Function Tests
    func testUnfollowNetwork_Success() async throws {
        try await service.unfollowProfileWith(domainName: mockDomainName, by: mockDomainDisplayInfo())
        XCTAssertEqual(networkService.unfollowCallDomainNames, [mockDomainName])
    }
    
    func testResetDataResetAfterUnfollow_Success() async throws {
        try await ensureFollowersResetAfterAsyncFunction {
            try await service.unfollowProfileWith(domainName: mockDomainName, by: mockDomainDisplayInfo())
        }
    }
    
    func testUnfollowNetwork_NetworkFailure() async throws {
        networkService.shouldFail = true
        
        do {
            try await service.unfollowProfileWith(domainName: mockDomainName, by: mockDomainDisplayInfo())
            XCTFail("Expected network error")
        } catch {
            assertNetworkErrorThrown(error)
        }
    }
    
    func testUnfollowActionSend_Success() async throws {
        let domain = mockDomainDisplayInfo()
        let action = DomainProfileFollowActionDetails(userDomainName: domain.name,
                                                      targetDomainName: mockDomainName,
                                                      isFollowing: false)
        try await ensureFollowingActionSend(action: action, by: domain)
    }
    
    func testUnfollowActionSend_Failure() async throws {
        networkService.shouldFail = true
        let receiver = CombineValuesCapturer(passthroughSubject: service.followActionsPublisher)
        try? await service.unfollowProfileWith(domainName: mockDomainName, by: mockDomainDisplayInfo())
        
        XCTAssertTrue(receiver.capturedValues.isEmpty)
    }
    
    // MARK: - Load More Tests
    func testLoadMoreCalledOnPublisherRequest() async throws {
        let receiver = await createWalletDomainProfileDetailsValuesReceiver(for: mockWallet())
        await Task.sleep(seconds: 0.1) // Wait for initial updates finished
        
        XCTAssertEqual(receiver.capturedValues.count, 4) // Initial + followers + followings + Public profile
        XCTAssertTrue(isSocialRelationshipDetailsEmpty(receiver.capturedValues[0].socialDetails!))
        XCTAssertNil(receiver.capturedValues[0].displayInfo)
        XCTAssertFalse(isSocialRelationshipDetailsEmpty(receiver.capturedValues[3].socialDetails!))
        XCTAssertNotNil(receiver.capturedValues[3].displayInfo)
    }
    
    func testCachedProfileUsedOnPublisherInit() async throws {
        let wallet = mockWallet()
        let profile = createMockDomainProfileAndStoreInCache(name: wallet.profileDomainName!)
        let receiver = await createWalletDomainProfileDetailsValuesReceiver(for: wallet)

        await Task.sleep(seconds: 0.1) // Wait for initial updates finished
        
        XCTAssertEqual(receiver.capturedValues[0].displayInfo, profile)
    }
    
    func testLoadMoreCalledOnPublishedRequestOnce() async {
        let wallet = mockWallet()
        let receiver = await createWalletDomainProfileDetailsValuesReceiver(for: wallet)

        await Task.sleep(seconds: 0.1) // Wait for initial updates finished
        XCTAssertFalse(receiver.capturedValues.isEmpty)
        receiver.clear()
        
        let samePublisher = await service.publisherForWalletDomainProfileDetails(wallet: wallet)
        await Task.sleep(seconds: 0.1)

        // Check no values were changed
        XCTAssertTrue(receiver.capturedValues.isEmpty)
    }
    
    // MARK: - Profile Suggestions tests
    func testEmptyProfileSuggestionsIfNoDomainInWallet() async throws {
        let walletWithoutDomain = MockEntitiesFabric.Wallet.mockEntities(hasRRDomain: false).first!
        let suggestions = try await service.getSuggestionsFor(wallet: walletWithoutDomain)
        
        XCTAssertTrue(networkService.suggestionsCallDomainNames.isEmpty)
        XCTAssertTrue(suggestions.isEmpty)
    }
    
    func testProfileSuggestionsReturnSuccess() async throws {
        let wallet = mockWallet()
        let suggestions = try await service.getSuggestionsFor(wallet: wallet)
        
        XCTAssertEqual(networkService.suggestionsCallDomainNames, [wallet.rrDomain!.name])
        XCTAssertEqual(suggestions.map { $0.domain }, networkService.suggestionToReturn.map { $0.domain })
    }
    
    func testProfileSuggestionsFails() async {
        networkService.shouldFail = true
        do {
            let wallet = mockWallet()
            let _ = try await service.getSuggestionsFor(wallet: wallet)
            XCTFail("Expected network error")
        } catch {
            assertNetworkErrorThrown(error)
        }
    }
}

// MARK: - Private methods
private extension DomainProfilesServiceTests {
    func mockWallet() -> WalletEntity {
        appContext.walletsDataService.wallets[0]
    }
    
    func mockDomainDisplayInfo() -> DomainDisplayInfo {
        mockWallet().rrDomain!
    }
    
    func createMockDomainProfileAndStoreInCache(name: String? = nil) -> DomainProfileDisplayInfo {
        let mockProfile = MockEntitiesFabric.PublicDomainProfile.createPublicDomainProfileDisplayInfo(domainName: name ?? mockDomainName)
        storage.store(profile: mockProfile)
        return mockProfile
    }
    
    func assertNetworkErrorThrown(_ error: Error) {
        XCTAssertEqual(error as? TestableGenericError, networkService.error)
    }
    
    func isSocialRelationshipDetailsEmpty(_ socialRelationshipDetails: DomainProfileSocialRelationshipDetails) -> Bool {
        isSocialDetailsEmpty(socialRelationshipDetails.followersDetails) &&
        isSocialDetailsEmpty(socialRelationshipDetails.followingDetails)
    }
    
    func isSocialDetailsEmpty(_ socialDetails: DomainProfileSocialRelationshipDetails.SocialDetails) -> Bool {
        socialDetails.domainNames.isEmpty &&
        socialDetails.paginationInfo.cursor == nil
    }
    
    func createWalletDomainProfileDetailsValuesReceiver(for wallet: WalletEntity) async -> CombineValuesCapturer<WalletDomainProfileDetails> {
        let publisher = await service.publisherForWalletDomainProfileDetails(wallet: wallet)
        let receiver = CombineValuesCapturer(currentValueSubject: publisher)
        return receiver
    }
    
    func ensureFollowersResetAfterAsyncFunction(_ block: @Sendable () async throws -> ())  async throws {
        let receiver = await createWalletDomainProfileDetailsValuesReceiver(for: mockWallet())

        await Task.sleep(seconds: 0.1) // Wait for initial updates finished
        receiver.clear()
        try await block()
        await Task.sleep(seconds: 0.1) // Wait for new expected requests finished
        
        XCTAssertEqual(receiver.capturedValues.count, 3) // Reset + followers + followings
        XCTAssertTrue(isSocialRelationshipDetailsEmpty(receiver.capturedValues[0].socialDetails!))
        XCTAssertFalse(isSocialRelationshipDetailsEmpty(receiver.capturedValues[1].socialDetails!))
        XCTAssertFalse(isSocialRelationshipDetailsEmpty(receiver.capturedValues[2].socialDetails!))
    }
    
    func ensureFollowingActionSend(action: DomainProfileFollowActionDetails,
                                   by domain: DomainDisplayInfo) async throws {
        let receiver = CombineValuesCapturer(passthroughSubject: service.followActionsPublisher)
        
        if action.isFollowing {
            try await service.followProfileWith(domainName: action.targetDomainName, by: domain)
        } else {
            try await service.unfollowProfileWith(domainName: action.targetDomainName, by: domain)
        }
        
        XCTAssertEqual(receiver.capturedValues, [action])
    }
}

private final class MockNetworkService: DomainProfileNetworkServiceProtocol, FailableService {
   
    var profileToReturn: SerializedPublicDomainProfile?
    var shouldFail = false
    var error: TestableGenericError { TestableGenericError.generic }
    var followCallDomainNames: [DomainName] = []
    var unfollowCallDomainNames: [DomainName] = []
    
    var suggestionToReturn: [SerializedDomainProfileSuggestion] = MockEntitiesFabric.ProfileSuggestions.createSerializedSuggestionsForPreview()
    var suggestionsCallDomainNames: [DomainName] = []
    
    func fetchPublicProfile(for domainName: DomainName, fields: Set<GetDomainProfileField>) async throws -> SerializedPublicDomainProfile {
        try failIfNeeded()
        if let profileToReturn {
            return profileToReturn
        }
        return MockEntitiesFabric.DomainProfile.createPublicProfile(domain: domainName)
    }
    
    func updateUserDomainProfile(for domain: DomainItem, request: ProfileUpdateRequest) async throws -> SerializedUserDomainProfile {
        // Not needed for now
        throw TestableGenericError.generic
    }
    
    func fetchListOfFollowers(for domain: DomainName,
                              relationshipType: DomainProfileFollowerRelationshipType,
                              count: Int,
                              cursor: Int?) async throws -> DomainProfileFollowersResponse {
        MockEntitiesFabric.DomainProfile.createFollowersResponseWithDomains(["domain.x"],
                                                                            take: 20,
                                                                            relationshipType: relationshipType)
    }
    
    func follow(_ domainNameToFollow: String, by domain: DomainItem) async throws {
        try failIfNeeded()
        followCallDomainNames.append(domainNameToFollow)
    }
    
    func unfollow(_ domainNameToUnfollow: String, by domain: DomainItem) async throws {
        try failIfNeeded()
        unfollowCallDomainNames.append(domainNameToUnfollow)
    }
    
    func getProfileSuggestions(for domainName: DomainName) async throws -> SerializedDomainProfileSuggestionsResponse {
        try failIfNeeded()
        suggestionsCallDomainNames.append(domainName)
        return suggestionToReturn
    }
    
    func getTrendingDomains() async throws -> domains_manager_ios.SerializedRankingDomainsResponse {
        []
    }
    
}

private final class MockStorage: DomainProfileDisplayInfoStorageServiceProtocol {
    
    var cache: [DomainName : DomainProfileDisplayInfo] = [:]
    
    func store(profile: DomainProfileDisplayInfo) {
        cache[profile.domainName] = profile
    }
    
    func retrieveProfileFor(domainName: DomainName) throws -> DomainProfileDisplayInfo {
        guard let profile = cache[domainName] else { throw MockStorageError.profileNotFound }
        
        return profile
    }
    
    enum MockStorageError: String, LocalizedError {
        case profileNotFound
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
