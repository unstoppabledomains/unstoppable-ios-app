//
//  MPCWalletPurchasingState.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.05.2024.
//

import Foundation

enum MPCWalletPurchasingState {
    case preparing
    case readyToPurchase(price: Int)
    case purchasing
    case failed(MPCWalletPurchaseError)
}
