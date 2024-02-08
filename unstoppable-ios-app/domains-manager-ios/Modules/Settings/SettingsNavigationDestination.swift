//
//  SettingsNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.02.2024.
//

import Foundation

enum SettingsNavigationDestination: Hashable {
    case walletsList(WalletsListViewPresenter.InitialAction)
    case login(LoginFlowNavigationController.Mode)
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.walletsList, .walletsList):
            return true
        case (.login, .login):
            return true
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .walletsList:
            hasher.combine("walletsList")
        case .login:
            hasher.combine("login")
        }
    }
    
}

