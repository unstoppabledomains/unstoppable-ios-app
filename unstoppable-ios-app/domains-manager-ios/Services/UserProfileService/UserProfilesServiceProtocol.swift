//
//  UserProfilesServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.02.2024.
//

import Foundation

protocol UserProfilesServiceProtocol {
    var selectedProfilePublisher: Published<UserProfile?>.Publisher  { get }
    var selectedProfile: UserProfile? { get }
    var profiles: [UserProfile] { get }
    
    func setActiveProfile(_ profile: UserProfile)
}
