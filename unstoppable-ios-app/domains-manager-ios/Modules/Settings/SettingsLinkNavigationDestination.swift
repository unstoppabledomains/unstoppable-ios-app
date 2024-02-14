//
//  SettingsLinkNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.02.2024.
//

import SwiftUI

struct SettingsLinkNavigationDestination {
    
    @ViewBuilder
    static func viewFor(navigationDestination: SettingsNavigationDestination) -> some View {
        switch navigationDestination {
        case .walletsList(let initialAction):
            WalletsListViewControllerWrapper(initialAction: initialAction)
                .toolbar(.hidden, for: .navigationBar)
        case .login(let mode):
            LoginFlowNavigationControllerWrapper(mode: mode)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
    
}
