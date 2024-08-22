//
//  PurchaseMPCWalletNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

extension PurchaseMPCWallet {
    enum NavigationDestination: Hashable {
        case enterTakoverCredentials(purchaseEmail: String?)
        case takeover(MPCTakeoverCredentials)
        
        var isWithCustomTitle: Bool { false }
    }
    
    struct LinkNavigationDestination {
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .enterTakoverCredentials(let purchaseEmail):
                PurchaseMPCWalletTakeoverCredentialsInAppView(purchaseEmail: purchaseEmail)
            case .takeover(let credentials):
                PurchaseMPCWalletTakeoverProgressInAppView(credentials: credentials)
            }
        }
    }
}
