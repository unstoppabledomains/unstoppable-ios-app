//
//  DomainProfilePendingChanges.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.12.2023.
//

import UIKit

struct DomainProfilePendingChanges: Codable {
    var avatarData: Data?
    var bannerData: Data?
    var name: String?
    var bio: String?
    var location: String?
    var website: String?
}
