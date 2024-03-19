//
//  UserProfilesServiceTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 19.03.2024.
//

import XCTest
@testable import domains_manager_ios
import Combine

final class UserProfilesServiceTests: BaseTestClass {
    
    private var firebaseParkedDomainsAuthenticationService: TestableFirebaseParkedDomainsAuthenticationService!
    private var firebaseParkedDomainsService: TestableFirebaseParkedDomainsService!
    private var walletsDataService: TestableWalletsDataService!
    private var userProfilesService: UserProfilesService!
    
    override func setUp() async throws {
        firebaseParkedDomainsAuthenticationService = TestableFirebaseParkedDomainsAuthenticationService()
        firebaseParkedDomainsService = TestableFirebaseParkedDomainsService()
        walletsDataService = TestableWalletsDataService()
        userProfilesService = UserProfilesService(firebaseParkedDomainsAuthenticationService:  firebaseParkedDomainsAuthenticationService,
                                                  firebaseParkedDomainsService: firebaseParkedDomainsService,
                                                  walletsDataService: walletsDataService)
    }
    
}

extension UserProfilesServiceTests {
    func testWillFetchProfilesFromAllSources() {
        
    }
    
    func testWillSetProfileOnInit() {
        
    }
}

// MARK: - Private methods
private extension UserProfilesServiceTests {
    func buildUserProfilesService(withWallets: Bool, cachedDomains: [FirebaseDomain]) {
        
    }
}
