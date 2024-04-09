//
//  FB_UD_MPCWalletAuthTokenProvider.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

extension FB_UD_MPC {
    protocol WalletAuthTokenProvider {
        func getAuthTokens(wallet: ConnectedWalletDetails) async throws -> String
    }
}
