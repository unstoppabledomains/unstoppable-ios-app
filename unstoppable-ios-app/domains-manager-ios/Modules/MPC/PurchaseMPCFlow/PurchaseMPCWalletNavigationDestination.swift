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
        case alreadyHaveWallet(email: String)
        case enterTakoverCredentials(purchaseEmail: String?)
        case enterTakoverRecovery(email: String)
        case takeover(MPCTakeoverCredentials)
        
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
            case .alreadyHaveWallet(let email):
                PurchaseMPCWalletAlreadyHaveWalletInAppView(email: email)
            case .enterTakoverCredentials(let purchaseEmail):
                PurchaseMPCWalletTakeoverCredentialsInAppView(purchaseEmail: purchaseEmail)
            case .enterTakoverRecovery(let email):
                PurchaseMPCWalletTakeoverRecoveryInAppView(email: email)
            case .takeover(let credentials):
                PurchaseMPCWalletTakeoverProgressInAppView(credentials: credentials)
            }
        }
    }
}
