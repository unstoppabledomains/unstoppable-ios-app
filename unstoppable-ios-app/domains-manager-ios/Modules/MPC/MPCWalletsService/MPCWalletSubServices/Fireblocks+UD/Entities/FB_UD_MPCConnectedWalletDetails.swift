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
        let tokens: AuthTokens
        let accounts: [WalletAccount]
        let assets: [WalletAccountAsset]
        
        init(deviceId: String, tokens: AuthTokens, accounts: [WalletAccount], assets: [WalletAccountAsset]) {
            self.deviceId = deviceId
            self.tokens = tokens
            self.accounts = accounts
            self.assets = assets
        }
        
        init(metadata: UDWalletMetadata, tokens: AuthTokens) {
            self.deviceId = metadata.deviceId
            self.tokens = tokens
            self.accounts = metadata.accounts
            self.assets = metadata.assets
        }

        func createUDWalletMetadata() -> UDWalletMetadata {
            UDWalletMetadata(deviceId: deviceId,
                             accounts: accounts,
                             assets: assets)
        }
    }
    
    struct UDWalletMetadata: Codable {
        let deviceId: String
        let accounts: [WalletAccount]
        let assets: [WalletAccountAsset]
    }
}
