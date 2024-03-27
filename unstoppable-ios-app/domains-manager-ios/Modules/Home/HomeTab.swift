//
//  HomeTab.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import SwiftUI

enum HomeTab: String, Hashable {
    case wallets
    case explore
    case activity
    case messaging
    
    var title: String {
        switch self {
        case .wallets:
            String.Constants.home.localized()
        case .explore:
            String.Constants.explore.localized()
        case .activity:
            String.Constants.activity.localized()
        case .messaging:
            String.Constants.messages.localized()
        }
    }
    
    var icon: Image {
        switch self {
        case .wallets:
                .homeLineIcon
        case .explore:
                .exploreIcon
        case .activity:
                .clock
        case .messaging:
                .messageCircleIcon24
        }
    }
    
}
