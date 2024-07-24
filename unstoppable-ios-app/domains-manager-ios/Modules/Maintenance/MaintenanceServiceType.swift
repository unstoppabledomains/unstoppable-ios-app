//
//  MaintenanceServiceType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2024.
//

import Foundation
import SwiftUI

enum MaintenanceServiceType {
    case full
    case activity
    case explore
    case home
    case purchaseDomains
    case vaultedDomains
    
    var title: String {
        switch self {
        case .full:
            return String.Constants.fullMaintenanceMessageTitle.localized()
        case .activity:
            return String.Constants.activityMaintenanceMessageTitle.localized()
        case .explore:
            return String.Constants.exploreMaintenanceMessageTitle.localized()
        case .home:
            return String.Constants.homeMaintenanceMessageTitle.localized()
        case .purchaseDomains:
            return String.Constants.purchaseDomainsMaintenanceMessageTitle.localized()
        case .vaultedDomains:
            return String.Constants.vaultedDomainsMaintenanceMessageTitle.localized()
        }
    }
    
    var message: String {
        switch self {
        case .full:
            return String.Constants.fullMaintenanceMessageSubtitle.localized()
        case .activity:
            return String.Constants.activityMaintenanceMessageSubtitle.localized()
        case .explore:
            return String.Constants.exploreMaintenanceMessageSubtitle.localized()
        case .home:
            return String.Constants.homeMaintenanceMessageSubtitle.localized()
        case .purchaseDomains:
            return String.Constants.purchaseDomainsMaintenanceMessageSubtitle.localized()
        case .vaultedDomains:
            return String.Constants.vaultedDomainsMaintenanceMessageSubtitle.localized()
        }
    }
    
    var icon: Image {
        switch self {
        case .full:
            return .udCartLogoRaster
        case .activity, .explore, .home, .vaultedDomains:
            return .infoIcon
        case .purchaseDomains:
            return .exploreFilledIcon
        }
    }
}
