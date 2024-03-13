//
//  TestableUserProfileService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import Foundation
@testable import domains_manager_ios
import Combine

final class TestableUserProfileService: UserProfileServiceProtocol {
   
    @Published var selectedProfile: UserProfile?
    var selectedProfilePublisher: Published<UserProfile?>.Publisher { $selectedProfile }
    
    var profiles: [UserProfile] = [MockEntitiesFabric.Profile.createWalletProfile()]
    
    init(profile: UserProfile?) {
        self.selectedProfile = profile
    }
    
    func setActiveProfile(_ profile: UserProfile) {
        selectedProfile = profile
    }
}
