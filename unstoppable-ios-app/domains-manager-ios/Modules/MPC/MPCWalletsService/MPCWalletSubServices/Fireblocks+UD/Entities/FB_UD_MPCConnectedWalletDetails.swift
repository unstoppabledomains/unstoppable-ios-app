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
        
        init(email: String,
             deviceId: String,
             tokens: AuthTokens,
             firstAccount: WalletAccountWithAssets,
             accounts: [WalletAccountWithAssets]) {
            self.email = email
            self.deviceId = deviceId
            self.tokens = tokens
            self.firstAccount = firstAccount
            self.accounts = accounts
        }
        
        init(accountDetails: ConnectedWalletAccountsDetails, tokens: AuthTokens) {
            self.email = accountDetails.email
            self.deviceId = accountDetails.deviceId
            self.tokens = tokens
            self.firstAccount = accountDetails.firstAccount
            self.accounts = accountDetails.accounts
        }
        
        func getETHWalletAddress() -> String? {
            firstAccount.assets.first(where: { $0.blockchainAsset.symbol == BlockchainType.Ethereum.shortCode })?.address
        }
        
        func createWalletAccountsDetails() -> ConnectedWalletAccountsDetails {
            ConnectedWalletAccountsDetails(email: email,
                                           deviceId: deviceId,
                                           firstAccount: firstAccount,
                                           accounts: accounts)
        }
    }
    
    struct ConnectedWalletAccountsDetails: Codable {
        let email: String
        let deviceId: String
        let firstAccount: WalletAccountWithAssets
        let accounts: [WalletAccountWithAssets]
    }
    
    struct UDWalletMetadata: Codable {
        let email: String
        let deviceId: String
    }
}
