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
        
        func getAssetWith(chain: BlockchainType) throws -> WalletAccountAsset {
            guard let asset = assets.first(where: { $0.blockchainAsset.symbol == chain.rawValue }) else { throw WalletAccountWithAssets.assetNotFound }
            return asset
        }
        
        init(account: WalletAccount,
             assets: [WalletAccountAsset]) {
            self.type = account.type
            self.id = account.id
            self.assets = assets
        }
        
        enum WalletAccountWithAssets: String, LocalizedError {
            case assetNotFound
            
            public var errorDescription: String? {
                return rawValue
            }
        }
    }
}
