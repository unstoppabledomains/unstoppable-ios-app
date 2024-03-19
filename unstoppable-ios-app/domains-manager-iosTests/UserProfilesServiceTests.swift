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
        let preSelectedProfile = UserProfile.webAccount(firebaseParkedDomainsAuthenticationService.mockFirebaseUser())
        buildUserProfilesService(isFBAuthorised: true,
                                 withParkedDomains: true,
                                 selectedProfileId: preSelectedProfile.id)
        XCTAssertEqual(userProfilesService.selectedProfile?.id, preSelectedProfile.id)
    }
}

// MARK: - Add first profile
extension UserProfilesServiceTests {
    func testFirstProfileFromWallet() async {
        let newWallet = walletsDataService.wallets[0]
        let expectedProfile = UserProfile.wallet(newWallet)

        buildUserProfilesService(withWallets: false,
                                 isFBAuthorised: false,
                                 withParkedDomains: false)
        walletsDataService.wallets.append(newWallet)
        await waitPublishersDelivered()
        verifySelectedProfileId(expectedProfile.id)
    }
    
    func testFirstProfileFromFBWithoutDomains() async {
        buildUserProfilesService(withWallets: false,
                                 isFBAuthorised: false,
                                 withParkedDomains: false)
        firebaseParkedDomainsAuthenticationService.simulateAuthorise()
        await waitPublishersDelivered()
        verifySelectedProfileId(nil)
    }
    
    func testFirstProfileFromFBWithDomains() async {
        let expectedProfile = UserProfile.webAccount(firebaseParkedDomainsAuthenticationService.mockFirebaseUser())
        
        buildUserProfilesService(withWallets: false,
                                 isFBAuthorised: false,
                                 withParkedDomains: true)
        firebaseParkedDomainsAuthenticationService.simulateAuthorise()
        await waitPublishersDelivered()
        verifySelectedProfileId(expectedProfile.id)
    }
}

// MARK: - Add/Remove Profile
extension UserProfilesServiceTests {
    func testNewWalletProfileAdded() async {
        let walletToAdd = walletsDataService.wallets.randomElement()!
        let profileToAdd = UserProfile.wallet(walletToAdd)
        
        buildUserProfilesService(withWallets: true,
                                 isFBAuthorised: false,
                                 withParkedDomains: false,
                                 extraSetupBlock: {
            self.walletsDataService.wallets.removeAll(where: { $0.address == walletToAdd.address })
        })
        XCTAssertNotEqual(profileToAdd.id, userProfilesService.selectedProfile?.id)
        walletsDataService.wallets.append(walletToAdd)
        await waitPublishersDelivered()
        verifySelectedProfileId(profileToAdd.id)
    }
    
    func testNewFBProfileWithoutDomainsAdded() async {
        buildUserProfilesService(withWallets: true,
                                 isFBAuthorised: false,
                                 withParkedDomains: false)
        let selectedProfile = userProfilesService.selectedProfile
        firebaseParkedDomainsAuthenticationService.simulateAuthorise()
        await waitPublishersDelivered()
        verifySelectedProfileId(selectedProfile?.id)
    }
    
    func testNewFBProfileWithDomainsAdded() async {
        let profileToAdd = UserProfile.webAccount(firebaseParkedDomainsAuthenticationService.mockFirebaseUser())
        
        buildUserProfilesService(withWallets: true,
                                 isFBAuthorised: false,
                                 withParkedDomains: true)

        firebaseParkedDomainsAuthenticationService.simulateAuthorise()
        await waitPublishersDelivered()
        verifySelectedProfileId(profileToAdd.id)
    }
    
    func testNewFBProfileWithDomainsFailedToFetchAdded() async {
        buildUserProfilesService(withWallets: true,
                                 isFBAuthorised: false,
                                 withParkedDomains: true,
                                 extraSetupBlock: {
            self.firebaseParkedDomainsService.shouldFail = true
        })
        let selectedProfile = userProfilesService.selectedProfile
        firebaseParkedDomainsAuthenticationService.simulateAuthorise()
        await waitPublishersDelivered()
        verifySelectedProfileId(selectedProfile?.id)
    }
    
    func testPreselectedOnlyProfileRemoved() {
        let preSelectedProfile = UserProfile.wallet(walletsDataService.wallets[1])
        buildUserProfilesService(withWallets: false,
                                 isFBAuthorised: false,
                                 withParkedDomains: false,
                                 selectedProfileId: preSelectedProfile.id)
        XCTAssertNil(storage.selectedProfileId)
    }
}

// MARK: - Switch profile
extension UserProfilesServiceTests {
    func testSelectedProfileChanged() {
        let newProfile = userProfilesService.profiles.first(where: { $0.id != userProfilesService.selectedProfile?.id })!
        userProfilesService.setActiveProfile(newProfile)
        verifySelectedProfileId(newProfile.id)
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
                                  selectedProfileId: String? = nil,
                                  extraSetupBlock: EmptyCallback? = nil) {
        firebaseParkedDomainsAuthenticationService = TestableFirebaseParkedDomainsAuthenticationService()
        if isFBAuthorised {
            firebaseParkedDomainsAuthenticationService.simulateAuthorise()
        }
        
        firebaseParkedDomainsService = TestableFirebaseParkedDomainsService()
        if withParkedDomains {
            firebaseParkedDomainsService.simulateParkedDomainsLoaded()
        }
        
        
        walletsDataService = TestableWalletsDataService()
        if !withWallets {
            walletsDataService.wrappedWallets.removeAll()
        }
        
        storage = UserProfilesStorage()
        storage.selectedProfileId = selectedProfileId
        
        extraSetupBlock?()
        
        userProfilesService = UserProfilesService(firebaseParkedDomainsAuthenticationService:  firebaseParkedDomainsAuthenticationService,
                                                  firebaseParkedDomainsService: firebaseParkedDomainsService,
                                                  walletsDataService: walletsDataService,
                                                  storage: storage)
    }
    
    func verifySelectedProfileId(_ id: String?) {
        XCTAssertEqual(userProfilesService.selectedProfile?.id, id)
        XCTAssertEqual(storage.selectedProfileId, id)
    }
    
}

final class UserProfilesStorage: SelectedUserProfileInfoStorageProtocol {
    var selectedProfileId: String? = nil
}
