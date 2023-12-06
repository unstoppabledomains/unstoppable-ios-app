//
//  DomainProfilePendingChanges.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.12.2023.
//

import UIKit

struct DomainProfilePendingChanges: Codable, Hashable {
    var avatarData: Data?
    var bannerData: Data?
    var name: String?
    var bio: String?
    var location: String?
    var website: String?
    
    var isEmpty: Bool {
        avatarData == nil &&
        bannerData == nil &&
        name == nil &&
        bio == nil &&
        location == nil &&
        website == nil
    }
}
