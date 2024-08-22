//
//  PurchaseMPCWalletNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

extension PurchaseMPCWallet {
    enum NavigationDestination: Hashable {
        case enterTakeoverCredentials(purchaseEmail: String?)
        case confirmTakeoverEmail(String)
        case takeover(MPCTakeoverCredentials)
        
        var isWithCustomTitle: Bool { false }
    }
    
    struct LinkNavigationDestination {
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .enterTakeoverCredentials(let purchaseEmail):
                PurchaseMPCWalletTakeoverCredentialsInAppView(purchaseEmail: purchaseEmail)
            case .confirmTakeoverEmail(let email):
                ConfirmTakeoverEmailInAppView(email: email)
            case .takeover(let credentials):
                PurchaseMPCWalletTakeoverProgressInAppView(credentials: credentials)
            }
        }
    }
}
