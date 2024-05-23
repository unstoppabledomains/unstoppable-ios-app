//
//  ActivateMPCWalletFlowNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.04.2024.
//

import SwiftUI

extension ActivateMPCWalletFlow {
    enum NavigationDestination: Hashable {
        case enterCode(email: String)
        case activate(credentials: MPCActivateCredentials, code: String)
        
        var isWithCustomTitle: Bool { false }
    }
    
    struct LinkNavigationDestination {
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .enterCode(let email):
                MPCEnterCodeInAppView(email: email)
            case .activate(let credentials, let code):
                MPCActivateWalletInAppView(credentials: credentials,
                                           code: code)
            }
        }
    }
}
