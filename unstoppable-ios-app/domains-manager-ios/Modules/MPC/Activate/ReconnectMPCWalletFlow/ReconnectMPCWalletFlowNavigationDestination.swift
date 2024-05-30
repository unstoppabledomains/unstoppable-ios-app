//
//  ReconnectMPCWalletFlowNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2024.
//

import SwiftUI

extension ReconnectMPCWalletFlow {
    enum NavigationDestination: Hashable {
        case enterCredentials(email: String)
        case enterCode(email: String)
        case activate(credentials: MPCActivateCredentials, code: String)
        
        var isWithCustomTitle: Bool { false }
    }
    
    struct LinkNavigationDestination {
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .enterCredentials(let email):
                MPCEnterCredentialsReconnectView(email: email)
            case .enterCode(let email):
                MPCEnterCodeReconnectView(email: email)
            case .activate(let credentials, let code):
                MPCActivateWalletReconnectView(credentials: credentials,
                                           code: code)
            }
        }
    }
}
