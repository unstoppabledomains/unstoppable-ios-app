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
        case activate(resetPasswordData: MPCResetPasswordData, code: String, newPassword: String)
        
        var isWithCustomTitle: Bool { false }
    }
    
    struct LinkNavigationDestination {
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .enterCode(let email):
                MPCEnterCodeInAppView(email: email)
            case .activate(let credentials, let code, let newPassword):
                MPCForgotPasswordView()
//                MPCActivateWalletInAppView(credentials: credentials,
//                                           code: code)
            }
        }
    }
}

