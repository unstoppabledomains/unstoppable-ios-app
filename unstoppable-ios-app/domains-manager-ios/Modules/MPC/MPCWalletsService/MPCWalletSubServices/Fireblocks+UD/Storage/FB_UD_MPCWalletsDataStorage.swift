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
        func retrieveAuthTokensFor(deviceId: String) throws -> AuthTokens
        
        func storeMetadata(_ metadata: UDWalletMetadata) throws
        func retrieveMetadataFor(deviceId: String) throws -> UDWalletMetadata
    }
}

