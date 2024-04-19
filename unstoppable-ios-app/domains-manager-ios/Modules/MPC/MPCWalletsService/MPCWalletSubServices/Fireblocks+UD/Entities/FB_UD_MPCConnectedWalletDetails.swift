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
        let firstAccount: WalletAccountWithAssets
        let accounts: [WalletAccountWithAssets]
        
        init(deviceId: String, 
             tokens: AuthTokens,
             firstAccount: WalletAccountWithAssets,
             accounts: [WalletAccountWithAssets]) {
            self.deviceId = deviceId
            self.tokens = tokens
            self.firstAccount = firstAccount
            self.accounts = accounts
        }
        
        init(accountDetails: ConnectedWalletAccountsDetails, tokens: AuthTokens) {
            self.deviceId = accountDetails.deviceId
            self.tokens = tokens
            self.firstAccount = accountDetails.firstAccount
            self.accounts = accountDetails.accounts
        }
        
        func getETHWalletAddress() -> String? {
            firstAccount.assets.first(where: { $0.blockchainAsset.symbol == BlockchainType.Ethereum.rawValue })?.address
        }
        
        func createWalletAccountsDetails() -> ConnectedWalletAccountsDetails {
            ConnectedWalletAccountsDetails(deviceId: deviceId,
                                           firstAccount: firstAccount,
                                           accounts: accounts)
        }
    }
    
    struct ConnectedWalletAccountsDetails: Codable {
        let deviceId: String
        let firstAccount: WalletAccountWithAssets
        let accounts: [WalletAccountWithAssets]
    }
    
    struct UDWalletMetadata: Codable {
        let deviceId: String
    }
}
