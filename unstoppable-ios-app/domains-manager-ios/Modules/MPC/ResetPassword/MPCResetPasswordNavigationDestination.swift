//
//  MPCResetPasswordNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.10.2024.
//

import SwiftUI

extension MPCResetPasswordFlow {
    enum NavigationDestination: Hashable {
        case enterCode(email: String)
        case activate(ResetPasswordFullData)
        
        var isWithCustomTitle: Bool { false }
    }
    
    struct LinkNavigationDestination {
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .enterCode(let email):
                MPCResetPasswordEnterCodeView(email: email)
            case .activate(let data):
                MPCResetPasswordActivateView(data: data)
            }
        }
    }
}

