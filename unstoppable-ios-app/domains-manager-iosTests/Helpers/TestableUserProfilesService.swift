//
//  TestableUserProfilesService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import Foundation
@testable import domains_manager_ios
import Combine

final class TestableUserProfilesService: UserProfilesServiceProtocol {
    
   
    @Published var selectedProfile: UserProfile?
    var selectedProfilePublisher: Published<UserProfile?>.Publisher { $selectedProfile }
    
    @Published private(set) var profiles: [UserProfile] = [MockEntitiesFabric.Profile.createWalletProfile()]
    var profilesPublisher: Published<[UserProfile]>.Publisher { $profiles }
    
    init(profile: UserProfile?) {
        self.selectedProfile = profile
    }
    
    func setActiveProfile(_ profile: UserProfile) {
        selectedProfile = profile
    }
}
