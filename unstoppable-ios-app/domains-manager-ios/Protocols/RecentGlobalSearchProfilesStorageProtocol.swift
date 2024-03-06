//
//  RecentGlobalSearchProfilesStorageProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.03.2024.
//

import Foundation

protocol RecentGlobalSearchProfilesStorageProtocol {
    func getRecentProfiles() -> [SearchDomainProfile]
    func addProfileToRecent(_ profile: SearchDomainProfile)
    func clearRecentProfiles()
}
