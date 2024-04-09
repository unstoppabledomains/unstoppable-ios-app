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
        
        init(accountDetails: ConnectedWalletAccountsDetails, tokens: AuthTokens) {
            self.deviceId = accountDetails.deviceId
            self.tokens = tokens
            self.accounts = accountDetails.accounts
            self.assets = accountDetails.assets
        }
        
        func getETHWalletAddress() -> String? {
            assets.first(where: { $0.blockchainAsset.symbol == BlockchainType.Ethereum.rawValue })?.address
        }
        
        func createWalletAccountsDetails() -> ConnectedWalletAccountsDetails {
            ConnectedWalletAccountsDetails(deviceId: deviceId,
                                           accounts: accounts,
                                           assets: assets)
        }
    }
    
    struct ConnectedWalletAccountsDetails: Codable {
        let deviceId: String
        let accounts: [WalletAccount]
        let assets: [WalletAccountAsset]
    }
    
    struct UDWalletMetadata: Codable {
        let deviceId: String
    }
}
