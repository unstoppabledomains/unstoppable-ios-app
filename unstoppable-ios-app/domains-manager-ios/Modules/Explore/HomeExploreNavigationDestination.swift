//
//  HomeExploreNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.02.2024.
//

import SwiftUI

enum HomeExploreNavigationDestination: Hashable {
    case suggestionsList
}

struct HomeExploreLinkNavigationDestination {
    
    @ViewBuilder
    static func viewFor(navigationDestination: HomeExploreNavigationDestination,
                        tabRouter: HomeTabRouter) -> some View {
        switch navigationDestination {
        case .suggestionsList:
            HomeExploreSuggestedProfilesListView()
        }
    }
    
}
