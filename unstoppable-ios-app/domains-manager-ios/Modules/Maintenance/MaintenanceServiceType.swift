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
    
    var title: String {
        switch self {
        case .activity:
            return String.Constants.activityMaintenanceMessageTitle.localized()
        }
    }
    
    var message: String {
        switch self {
        case .activity:
            return String.Constants.activityMaintenanceMessageSubtitle.localized()
        }
    }
    
    var icon: Image {
        switch self {
        case .activity:
            return .infoIcon
        }
    }
}
