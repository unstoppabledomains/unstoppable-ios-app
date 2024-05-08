//
//  FB_UD_MPCAccountBalance.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

extension FB_UD_MPC {
    struct WalletAccountAsset: Codable {
        let type: String
        let id: String
        let address: String
        let balance: Balance?
        let blockchainAsset: BlockchainAsset
        
        private enum CodingKeys: String, CodingKey {
            case type = "@type"
            case id
            case address
            case balance
            case blockchainAsset
        }
        
        struct Balance: Codable {
            let total: String
            let decimals: Int
        }
    }
    
    struct WalletAccountAssetsResponse: Codable {
        let items: [WalletAccountAsset]
        let next: String?
    }
}

extension Array where Element == FB_UD_MPC.WalletAccountAsset {
    func findWith(symbol: String, chain: String) -> Element? {
        // TODO: - Check for $0.blockchainAsset.blockchain.symbol when BE ready
        first(where: { $0.blockchainAsset.symbol == symbol && $0.blockchainAsset.blockchain.id == chain })
    }
}
