//
//  UDFeatureFlag.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.10.2023.
//

import Foundation

enum UDFeatureFlag: String, CaseIterable {
    case communityMediaEnabled = "ecommerce-service-users-enable-chat-community-media"
    case isBuyCryptoEnabled = "mobile-buy-crypto-enabled"
    case isSendCryptoEnabled = "mobile-send-crypto-enabled"
    
    case isMPCWalletEnabled = "mobile-mpc-wallet-enabled"
    case isMPCSendCryptoEnabled = "mobile-mpc-send-crypto-enabled"
    
    var defaultValue: Bool {
        switch self {
        case .communityMediaEnabled, .isBuyCryptoEnabled:
            return false
        case .isSendCryptoEnabled, .isMPCWalletEnabled, .isMPCSendCryptoEnabled:
            return true
        }
    }
}
