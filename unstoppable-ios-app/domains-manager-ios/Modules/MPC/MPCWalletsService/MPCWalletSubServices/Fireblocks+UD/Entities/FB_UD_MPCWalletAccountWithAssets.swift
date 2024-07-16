//
//  FB_UD_MPCWalletAccountWithAssets.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.04.2024.
//

import Foundation

extension FB_UD_MPC {
    struct WalletAccountWithAssets: Codable {
        let type: String
        let id: String
        let assets: [WalletAccountAsset]
        
        func getAssetToSignWith(chain: BlockchainType) throws -> WalletAccountAsset {
            try getAssetWith(symbol: chain.shortCode, chain: chain.shortCode)
        }
        
        func getAssetWith(symbol: String, chain: String) throws -> WalletAccountAsset {
            guard let asset = assets.findWith(symbol: symbol, chain: chain) else { throw WalletAccountWithAssetsError.assetNotFound }
            return asset
        }
        
        func canSendCryptoTo(symbol: String,
                             chain: String) -> Bool {
            let asset = try? getAssetWith(symbol: symbol, chain: chain)
            return asset != nil
        }
        
        func createTokens() -> [BalanceTokenUIDescription] {
            assets.map { $0.createTokenUIDescription() }
        }
        
        init(account: WalletAccount,
             assets: [WalletAccountAsset]) {
            self.type = account.type
            self.id = account.id
            self.assets = assets
        }
        
        enum WalletAccountWithAssetsError: String, LocalizedError {
            case assetNotFound
            
            public var errorDescription: String? {
                return rawValue
            }
        }
    }
}
