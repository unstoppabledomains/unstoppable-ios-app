//
//  UDMPCWallet.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.03.2024.
//

import Foundation

extension FB_UD_MPC {
    struct ConnectedWalletDetails {
        let deviceId: String
        let tokens: Tokens
        
        struct Tokens {
            var refreshToken: JWToken
            var bootstrapToken: JWToken
        }
    }
}
