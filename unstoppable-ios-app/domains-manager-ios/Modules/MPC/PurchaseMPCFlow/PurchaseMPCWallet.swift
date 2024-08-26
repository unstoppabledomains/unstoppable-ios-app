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
        case createNewWallet
        case createMPCWallet
        case didEnterTakeoverEmail(String)
        case didEnterTakeoverPassword(String)
        case didEnterTakeover(code: String)
        case didFinishTakeover
        case didEnterActivation(code: String)
        case didActivate(UDWallet)
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
