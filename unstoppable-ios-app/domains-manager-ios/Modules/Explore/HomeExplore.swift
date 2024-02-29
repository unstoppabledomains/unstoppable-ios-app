//
//  HomeExplore.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.02.2024.
//

import SwiftUI

// Namespace
enum HomeExplore { }

extension HomeExplore {
    enum SearchDomainsType: String, CaseIterable, UDSegmentedControlItem {
        case global, local
        
        var title: String {
            switch self {
            case .global:
                return String.Constants.global.localized()
            case .local:
                return String.Constants.yours.localized()
            }
        }
        
        var icon: Image? {
            switch self {
            case .global:
                return .globeBold
            case .local:
                return .walletExternalIcon
            }
        }
        
        var analyticButton: Analytics.Button { .exploreDomainsSearchType }
    }
}
