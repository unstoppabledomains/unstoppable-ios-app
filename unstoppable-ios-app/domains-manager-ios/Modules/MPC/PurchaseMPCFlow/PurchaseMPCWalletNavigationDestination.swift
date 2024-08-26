//
//  PurchaseMPCWalletNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

extension PurchaseMPCWallet {
    enum NavigationDestination: Hashable {
        case enterTakeoverCredentials
        case enterTakeoverPassword
        case enterTakeoverCode(email: String)
        case takeover(MPCTakeoverCredentials)
        case almostThere
        case enterActivationCode(email: String)
        case activate(credentials: MPCTakeoverCredentials)

        var isWithCustomTitle: Bool { false }
    }
    
    struct LinkNavigationDestination {
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .enterTakeoverCredentials:
                PurchaseMPCWalletTakeoverEmailInAppView()
            case .enterTakeoverPassword:
                PurchaseMPCWalletTakeoverPasswordInAppView()
            case .enterTakeoverCode(let email):
                MPCEnterTakeoverCodeInAppView(email: email)
            case .takeover(let credentials):
                PurchaseMPCWalletTakeoverProgressInAppView(credentials: credentials)
            case .almostThere:
                PurchaseMPCWalletAlmostThereInAppView()
            case .enterActivationCode(let email):
                MPCEnterCodeInAppAfterClaimView(email: email)
            case .activate(let credentials):
                MPCActivateWalletInAppAfterClaimView(credentials: MPCActivateCredentials(email: credentials.email,
                                                                                         password: credentials.password),
                                                     code: credentials.code)
            }
        }
    }
}
