//
//  PurchaseMPCWalletNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

extension PurchaseMPCWallet {
    enum NavigationDestination: Hashable {
        case udAuth
        case checkout(MPCPurchaseUDCredentials)
        
        var isWithCustomTitle: Bool { false }
    }
    
    struct LinkNavigationDestination {
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .udAuth:
                PurchaseMPCWalletUDAuthInAppView()
            case .checkout(let credentials):
                PurchaseMPCWalletCheckoutInAppView(credentials: credentials)
            }
        }
    }
}
