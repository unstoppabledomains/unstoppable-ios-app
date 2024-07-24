//
//  MaintenanceServiceType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2024.
//

import Foundation
import SwiftUI

enum MaintenanceServiceType {
    case activity
    case explore
    case home
    
    var title: String {
        switch self {
        case .activity:
            return String.Constants.activityMaintenanceMessageTitle.localized()
        case .explore:
            return String.Constants.exploreMaintenanceMessageTitle.localized()
        case .home:
            return String.Constants.homeMaintenanceMessageTitle.localized()
        }
    }
    
    var message: String {
        switch self {
        case .activity:
            return String.Constants.activityMaintenanceMessageSubtitle.localized()
        case .explore:
            return String.Constants.exploreMaintenanceMessageSubtitle.localized()
        case .home:
            return String.Constants.homeMaintenanceMessageSubtitle.localized()
        }
    }
    
    var icon: Image {
        switch self {
        case .activity, .explore, .home:
            return .infoIcon
        }
    }
}
