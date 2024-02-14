//
//  UserProfileServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.02.2024.
//

import Foundation

protocol UserProfileServiceProtocol {
    var selectedProfilePublisher: Published<UserProfile?>.Publisher  { get }
    var selectedProfile: UserProfile? { get }
    var profiles: [UserProfile] { get }
    
    func setSelectedProfile(_ profile: UserProfile)
}
