//
//  UDMPCWallet.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.03.2024.
//

import Foundation

extension FB_UD_MPC {
    struct ConnectedWalletDetails {
        let email: String
        let deviceId: String
        let tokens: AuthTokens
        let firstAccount: WalletAccountWithAssets
        let accounts: [WalletAccountWithAssets]
        let is2FAEnabled: Bool
        
        init(email: String,
             deviceId: String,
             tokens: AuthTokens,
             firstAccount: WalletAccountWithAssets,
             accounts: [WalletAccountWithAssets],
             is2FAEnabled: Bool) {
            self.email = email
            self.deviceId = deviceId
            self.tokens = tokens
            self.firstAccount = firstAccount
            self.accounts = accounts
            self.is2FAEnabled = is2FAEnabled
        }
        
        init(accountDetails: ConnectedWalletAccountsDetails,
             tokens: AuthTokens,
             is2FAEnabled: Bool) {
            self.email = accountDetails.email
            self.deviceId = accountDetails.deviceId
            self.tokens = tokens
            self.firstAccount = accountDetails.firstAccount
            self.accounts = accountDetails.accounts
            self.is2FAEnabled = is2FAEnabled
        }
        
        func getETHWalletAddress() -> String? {
            firstAccount.assets.first(where: { $0.blockchainAsset.symbol == BlockchainType.Ethereum.shortCode })?.address
        }
        
        func createWalletAccountsDetails() -> ConnectedWalletAccountsDetails {
            ConnectedWalletAccountsDetails(email: email,
                                           deviceId: deviceId,
                                           firstAccount: firstAccount,
                                           accounts: accounts,
                                           is2FAEnabled: is2FAEnabled)
        }
    }
    
    struct ConnectedWalletAccountsDetails: Codable {
        let email: String
        let deviceId: String
        let firstAccount: WalletAccountWithAssets
        let accounts: [WalletAccountWithAssets]
        var is2FAEnabled: Bool? = nil
    }
    
    struct UDWalletMetadata: Codable {
        let email: String
        let deviceId: String
    }
}
