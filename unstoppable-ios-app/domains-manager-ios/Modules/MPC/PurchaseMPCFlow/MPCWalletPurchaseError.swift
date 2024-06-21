//
//  MPCWalletPurchaseError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import Foundation

enum MPCWalletPurchaseError: String, LocalizedError {
    case walletAlreadyPurchased
    case unknown
    
    public var errorDescription: String? {
        return rawValue
    }
}
