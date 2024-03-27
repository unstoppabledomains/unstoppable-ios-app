//
//  HomeActivityNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import SwiftUI

enum HomeActivityNavigationDestination: Hashable {
    
}

struct HomeActivityLinkNavigationDestination {
    
    @ViewBuilder
    static func viewFor(navigationDestination: HomeActivityNavigationDestination,
                        tabRouter: HomeTabRouter) -> some View {
        switch navigationDestination {
        default:
            EmptyView()
        }
    }
    
}

