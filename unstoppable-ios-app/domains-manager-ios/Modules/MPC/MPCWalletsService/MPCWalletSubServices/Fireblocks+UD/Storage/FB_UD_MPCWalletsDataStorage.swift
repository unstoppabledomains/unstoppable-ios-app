//
//  FB_UD_MPCWalletsDataStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

extension FB_UD_MPC {
    protocol MPCWalletsDataStorage {
        func storeAuthTokens(_ tokens: AuthTokens, for deviceId: String) throws
        func clearAuthTokensFor(deviceId: String) throws
        func retrieveAuthTokensFor(deviceId: String) throws -> AuthTokens
        
        func storeAccountsDetails(_ accountsDetails: ConnectedWalletAccountsDetails) throws
        func clearAccountsDetailsFor(deviceId: String) throws
        func retrieveAccountsDetailsFor(deviceId: String) throws -> ConnectedWalletAccountsDetails
    }
}

