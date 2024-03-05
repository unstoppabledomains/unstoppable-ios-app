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
    
    func test_getCachedPublicDomainProfileDisplayInfo_returnsCachedValue() throws {
        let mockProfile = MockEntitiesFabric.PublicDomainProfile.createPublicDomainProfileDisplayInfo(domainName: "test.x")
        storage.store(profile: mockProfile)
        
        let cachedProfile = service.getCachedPublicDomainProfileDisplayInfo(for: "test.x")
        
        XCTAssertEqual(cachedProfile, mockProfile)
    }
    
    func test_getCachedPublicDomainProfileDisplayInfo_returnsNilForMissingCache() {
        let cachedProfile = service.getCachedPublicDomainProfileDisplayInfo(for: "test.x")
        
        XCTAssertNil(cachedProfile)
    }
    
    func test_getCachedAndRefreshProfileStream_yieldsCachedProfileThenRefreshed() async throws {
        let cachedProfile = MockEntitiesFabric.PublicDomainProfile.createPublicDomainProfileDisplayInfo(domainName: mockDomainName)
        storage.cache = [mockDomainName: cachedProfile]
        
        let refreshedSerializedProfile = MockEntitiesFabric.DomainProfile.createPublicProfile(domain: mockDomainName)
        networkService.profileToReturn = refreshedSerializedProfile
        let refreshedPublicProfile = PublicDomainProfileDisplayInfo(serializedProfile: refreshedSerializedProfile)
        
        let stream = service.getCachedAndRefreshProfileStream(for: mockDomainName)
        
        var receivedValues: [PublicDomainProfileDisplayInfo] = []
        do {
            for try await value in stream {
                receivedValues.append(value)
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        XCTAssertEqual(receivedValues.count, 2)
        XCTAssertEqual(receivedValues[0], cachedProfile)
        XCTAssertEqual(receivedValues[1], refreshedPublicProfile)
    }
    
    
    func test_getCachedAndRefreshProfileStream_yieldsOnlyRefreshedProfileIfNoCache() async throws {
        let refreshedSerializedProfile = MockEntitiesFabric.DomainProfile.createPublicProfile(domain: mockDomainName)
        networkService.profileToReturn = refreshedSerializedProfile
        let refreshedPublicProfile = PublicDomainProfileDisplayInfo(serializedProfile: refreshedSerializedProfile)
        
        let stream = service.getCachedAndRefreshProfileStream(for: mockDomainName)
        
        var receivedValues: [PublicDomainProfileDisplayInfo] = []
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
        let stream = service.getCachedAndRefreshProfileStream(for: mockDomainName)
        
        do {
            for try await _ in stream {
                XCTFail("Expected network error to be thrown")
            }
        } catch {
            XCTAssertEqual(error as? MockNetworkService.GenericError, networkService.error)
        }
    }
}

// MARK: - Private methods
private extension DomainProfilesServiceTests {
    func mockWallet() -> WalletEntity {
        MockEntitiesFabric.Wallet.mockEntities()[0]
    }
}

private final class MockNetworkService: PublicDomainProfileNetworkServiceProtocol {
    var profileToReturn: SerializedPublicDomainProfile?
    var shouldFail = false
    var error: GenericError { GenericError.generic }
    
    func fetchPublicProfile(for domainName: DomainName, fields: Set<GetDomainProfileField>) async throws -> SerializedPublicDomainProfile {
        try failIfNeeded()
        if let profileToReturn {
            return profileToReturn
        }
        return MockEntitiesFabric.DomainProfile.createPublicProfile(domain: domainName)
    }
    
    func follow(_ domainNameToFollow: String, by domain: domains_manager_ios.DomainItem) async throws {
        try failIfNeeded()
    }
    
    func unfollow(_ domainNameToUnfollow: String, by domain: domains_manager_ios.DomainItem) async throws {
        try failIfNeeded()
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

private final class MockStorage: PublicDomainProfileDisplayInfoStorageServiceProtocol {
    
    var cache: [DomainName : PublicDomainProfileDisplayInfo] = [:]
    
    func store(profile: PublicDomainProfileDisplayInfo) {
        cache[profile.domainName] = profile
    }
    
    func retrieveProfileFor(domainName: DomainName) throws -> PublicDomainProfileDisplayInfo {
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
