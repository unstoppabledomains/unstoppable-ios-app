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
                                        storage: storage)
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
    
    func testFollowPublisher_Success() async throws {
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
    
    // MARK: - Unfollow Function Tests
    func testUnfollowNetwork_Success() async throws {
        try await service.unfollowProfileWith(domainName: mockDomainName, by: mockDomainDisplayInfo())
        XCTAssertEqual(networkService.unfollowCallDomainNames, [mockDomainName])
    }
    
    func testUnfollowPublisher_Success() async throws {
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
    
    // MARK: - Load More Tests
    func testLoadMoreCalledOnPublisherRequest() async throws {
        let publisher = await service.publisherForWalletDomainProfileDetails(wallet: mockWallet())
        var capturedValues: [WalletDomainProfileDetails] = []
        let cancellable = publisher.sink { value in
            capturedValues.append(value)
        }
        await Task.sleep(seconds: 0.1) // Wait for initial updates finished
        
        XCTAssertEqual(capturedValues.count, 4) // Initial + followers + followings + Public profile
        XCTAssertTrue(isSocialRelationshipDetailsEmpty(capturedValues[0].socialDetails!))
        XCTAssertNil(capturedValues[0].displayInfo)
        XCTAssertFalse(isSocialRelationshipDetailsEmpty(capturedValues[3].socialDetails!))
        XCTAssertNotNil(capturedValues[3].displayInfo)
    }
    
    func testCachedProfileUsedOnPublisherInit() async throws {
        let wallet = mockWallet()
        let profile = createMockDomainProfileAndStoreInCache(name: wallet.profileDomainName!)
        let publisher = await service.publisherForWalletDomainProfileDetails(wallet: wallet)
        var capturedValues: [WalletDomainProfileDetails] = []
        let cancellable = publisher.sink { value in
            capturedValues.append(value)
        }
        await Task.sleep(seconds: 0.1) // Wait for initial updates finished
        
        XCTAssertEqual(capturedValues[0].displayInfo, profile)
    }
    
    func testLoadMoreCalledOnPublishedRequestOnce() async {
        let wallet = mockWallet()
        let publisher = await service.publisherForWalletDomainProfileDetails(wallet: wallet)
        var capturedValues: [WalletDomainProfileDetails] = []
        let cancellable = publisher.sink { value in
            capturedValues.append(value)
        }
        await Task.sleep(seconds: 0.1) // Wait for initial updates finished
        XCTAssertFalse(capturedValues.isEmpty)
        capturedValues.removeAll()
        
        let samePublisher = await service.publisherForWalletDomainProfileDetails(wallet: wallet)
        await Task.sleep(seconds: 0.1)

        // Check no values were changed
        XCTAssertTrue(capturedValues.isEmpty)
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
        XCTAssertEqual(error as? MockNetworkService.GenericError, networkService.error)
    }
    
    func isSocialRelationshipDetailsEmpty(_ socialRelationshipDetails: DomainProfileSocialRelationshipDetails) -> Bool {
        isSocialDetailsEmpty(socialRelationshipDetails.followersDetails) &&
        isSocialDetailsEmpty(socialRelationshipDetails.followingDetails)
    }
    
    func isSocialDetailsEmpty(_ socialDetails: DomainProfileSocialRelationshipDetails.SocialDetails) -> Bool {
        socialDetails.domainNames.isEmpty &&
        socialDetails.paginationInfo.cursor == nil
    }
    
    func ensureFollowersResetAfterAsyncFunction(_ block: @Sendable () async throws -> ())  async throws {
        let publisher = await service.publisherForWalletDomainProfileDetails(wallet: mockWallet())
        var capturedValues: [WalletDomainProfileDetails] = []
        let cancellable = publisher.sink { value in
            capturedValues.append(value)
        }
        
        await Task.sleep(seconds: 0.1) // Wait for initial updates finished
        capturedValues.removeAll()
        try await block()
        await Task.sleep(seconds: 0.1) // Wait for new expected requests finished
        
        XCTAssertEqual(capturedValues.count, 3) // Reset + followers + followings
        XCTAssertTrue(isSocialRelationshipDetailsEmpty(capturedValues[0].socialDetails!))
        XCTAssertFalse(isSocialRelationshipDetailsEmpty(capturedValues[1].socialDetails!))
        XCTAssertFalse(isSocialRelationshipDetailsEmpty(capturedValues[2].socialDetails!))
        cancellable.cancel()
    }
}

private final class MockNetworkService: DomainProfileNetworkServiceProtocol {
    var profileToReturn: SerializedPublicDomainProfile?
    var shouldFail = false
    var error: GenericError { GenericError.generic }
    var followCallDomainNames: [DomainName] = []
    var unfollowCallDomainNames: [DomainName] = []
    
    func fetchPublicProfile(for domainName: DomainName, fields: Set<GetDomainProfileField>) async throws -> SerializedPublicDomainProfile {
        try failIfNeeded()
        if let profileToReturn {
            return profileToReturn
        }
        return MockEntitiesFabric.DomainProfile.createPublicProfile(domain: domainName)
    }
    
    func updateUserDomainProfile(for domain: DomainItem, request: ProfileUpdateRequest) async throws -> SerializedUserDomainProfile {
        // Not needed for now
        throw GenericError.generic
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
    
    private func failIfNeeded() throws {
        if shouldFail {
            throw GenericError.generic
        }
    }
    
    enum GenericError: String, LocalizedError {
        case generic
        
        public var errorDescription: String? {
            return rawValue
        }
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
