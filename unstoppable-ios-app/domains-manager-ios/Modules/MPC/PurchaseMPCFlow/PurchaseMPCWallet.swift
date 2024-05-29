//
//  PurchaseMPCWallet.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import Foundation

enum PurchaseMPCWallet { }

extension PurchaseMPCWallet {
    enum FlowAction {
        case authWithProvider(LoginProvider)
        case loginWithEmail(email: String, password: String)
        case didPurchase
    }
    
    enum PurchaseResult {
        case purchased
        case alreadyHaveWallet
    }
    
    enum AlreadyHaveWalletAction {
        case useDifferentEmail
        case importMPC
    }
}
