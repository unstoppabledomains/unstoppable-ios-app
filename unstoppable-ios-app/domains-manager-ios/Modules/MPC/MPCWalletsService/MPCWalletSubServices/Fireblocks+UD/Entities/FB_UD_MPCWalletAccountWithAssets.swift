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
            try getAssetWith(symbol: chain.rawValue, chain: mpcIDFor(chain: chain))
        }
        
        func getAssetWith(symbol: String, chain: String) throws -> WalletAccountAsset {
            let chain = try mpcIDFor(symbol: chain)
            guard let asset = assets.findWith(symbol: symbol, chain: chain) else { throw WalletAccountWithAssets.assetNotFound }
            return asset
        }
        
        func canSendCryptoTo(symbol: String,
                             chain: String) -> Bool {
            let asset = try? getAssetWith(symbol: symbol, chain: chain)
            return asset != nil
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
        
        private func mpcIDFor(chain: BlockchainType) -> String {
            switch chain {
            case .Ethereum:
                "ETHEREUM"
            case .Matic:
                "POLYGON"
            }
        }
        
        private func mpcIDFor(symbol: String) throws -> String {
            switch symbol {
            case "ETH":
                return "ETHEREUM"
            case "MATIC":
                return "POLYGON"
            default:
                throw WalletAccountWithAssets.assetNotFound
            }
        }
    }
}
