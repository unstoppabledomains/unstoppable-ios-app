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
    private var storage: UserProfilesStorage!
    private var userProfilesService: UserProfilesService!
    
    override func setUp() async throws {
        buildUserProfilesService()
    }
    
}

// MARK: - Test initial interaction with other services
extension UserProfilesServiceTests {
    func testWillFetchWalletsOnInit() {
        XCTAssertTrue(walletsDataService.numberOfGetWalletsCalls > 0)
    }
    
    func testWillNotFetchParkedDomainsIfNotAuthorised() {
        buildUserProfilesService()
        XCTAssertEqual(firebaseParkedDomainsService.numberOfGetCachedDomainsCalls, 0)
    }
    
    func testWillFetchParkedDomainsIfAuthorised() {
        buildUserProfilesService(isFBAuthorised: true)
        XCTAssertTrue(firebaseParkedDomainsService.numberOfGetCachedDomainsCalls > 0)
    }
}

// MARK: - Number of profiles
extension UserProfilesServiceTests {
    func testNumberOfProfilesMatchWallets() {
        buildUserProfilesService(isFBAuthorised: false, withParkedDomains: true)
        XCTAssertEqual(userProfilesService.profiles.count, walletsDataService.wallets.count)
    }
    
    func testNumberOfProfilesMatchWalletsIfNoFBDomains() {
        buildUserProfilesService(isFBAuthorised: true, withParkedDomains: false)
        XCTAssertEqual(userProfilesService.profiles.count, walletsDataService.wallets.count)
    }
    
    func testNumberOfProfilesWithFBAccount() {
        buildUserProfilesService(isFBAuthorised: true, withParkedDomains: true)
        XCTAssertEqual(userProfilesService.profiles.count, walletsDataService.wallets.count + 1)
    }
}

// MARK: - Initial profile resolved
extension UserProfilesServiceTests {
    func testNoPreviouslySelectedProfileWhenWalletsOnly() {
        buildUserProfilesService(isFBAuthorised: false, 
                                 withParkedDomains: false)
        XCTAssertEqual(userProfilesService.selectedProfile?.id, walletsDataService.wallets.first?.address)
    }
    
    func testPreviouslySelectedProfileWalletsOnly() {
        let preSelectedProfile = UserProfile.wallet(walletsDataService.wallets[1])
        buildUserProfilesService(isFBAuthorised: false,
                                 withParkedDomains: false,
                                 selectedProfileId: preSelectedProfile.id)
        XCTAssertEqual(userProfilesService.selectedProfile?.id, preSelectedProfile.id)
    }
    
    func testNoPreviouslySelectedProfileWhenWalletsAndFB() {
        buildUserProfilesService(isFBAuthorised: true, 
                                 withParkedDomains: true)
        XCTAssertEqual(userProfilesService.selectedProfile?.id, walletsDataService.wallets.first?.address)
    }
    
    func testPreviouslySelectedWalletProfileWhenWalletsAndFB() {
        let preSelectedProfile = UserProfile.wallet(walletsDataService.wallets[1])
        buildUserProfilesService(isFBAuthorised: true,
                                 withParkedDomains: true,
                                 selectedProfileId: preSelectedProfile.id)
        XCTAssertEqual(userProfilesService.selectedProfile?.id, preSelectedProfile.id)
    }
    
    func testPreviouslySelectedFBProfileWhenWalletsAndFB() {
        firebaseParkedDomainsAuthenticationService.setFirebaseUser()
        let preSelectedProfile = UserProfile.webAccount(firebaseParkedDomainsAuthenticationService.firebaseUser!)
        buildUserProfilesService(isFBAuthorised: true,
                                 withParkedDomains: true,
                                 selectedProfileId: preSelectedProfile.id)
        XCTAssertEqual(userProfilesService.selectedProfile?.id, preSelectedProfile.id)
    }
}

// MARK: - Open methods
extension UserProfilesServiceTests {
    func testPreselectedOnlyProfileRemoved() {
        let preSelectedProfile = UserProfile.wallet(walletsDataService.wallets[1])
        buildUserProfilesService(withWallets: false,
                                 isFBAuthorised: false,
                                 withParkedDomains: false,
                                 selectedProfileId: preSelectedProfile.id)
        XCTAssertNil(storage.selectedProfileId)
    }
    
    func testNewProfileFromNilWallet() async {
        let newWallet = walletsDataService.wallets[0]
        let expectedProfile = UserProfile.wallet(newWallet)

        buildUserProfilesService(withWallets: false,
                                 isFBAuthorised: false,
                                 withParkedDomains: false)
        walletsDataService.wallets.append(newWallet)
        await waitPublishersDelivered()
        XCTAssertEqual(userProfilesService.selectedProfile?.id, expectedProfile.id)
        XCTAssertEqual(storage.selectedProfileId, expectedProfile.id)
    }
    
    func testNewProfileFromNilFB() {
        buildUserProfilesService(withWallets: false,
                                 isFBAuthorised: false,
                                 withParkedDomains: false)
    }
}

// MARK: - Private methods
private extension UserProfilesServiceTests {
    func waitPublishersDelivered() async {
        await Task.sleep(seconds: 0.2)
    }
    
    func buildUserProfilesService(withWallets: Bool = true,
                                  isFBAuthorised: Bool = false,
                                  withParkedDomains: Bool = true,
                                  selectedProfileId: String? = nil) {
        firebaseParkedDomainsAuthenticationService = TestableFirebaseParkedDomainsAuthenticationService()
        if isFBAuthorised {
            firebaseParkedDomainsAuthenticationService.setFirebaseUser()
        }
        
        firebaseParkedDomainsService = TestableFirebaseParkedDomainsService()
        if withParkedDomains {
            firebaseParkedDomainsService.domainsToReturn = MockEntitiesFabric.Domains.mockFirebaseDomains()
        }
        
        
        walletsDataService = TestableWalletsDataService()
        if !withWallets {
            walletsDataService.wrappedWallets.removeAll()
        }
        
        storage = UserProfilesStorage()
        storage.selectedProfileId = selectedProfileId
        
        userProfilesService = UserProfilesService(firebaseParkedDomainsAuthenticationService:  firebaseParkedDomainsAuthenticationService,
                                                  firebaseParkedDomainsService: firebaseParkedDomainsService,
                                                  walletsDataService: walletsDataService,
                                                  storage: storage)
    }
}

final class UserProfilesStorage: SelectedUserProfileInfoStorageProtocol {
    var selectedProfileId: String? = nil
}
