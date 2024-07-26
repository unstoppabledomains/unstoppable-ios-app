//
//  FB_UD_MPCBlockchain.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

extension FB_UD_MPC {
    struct BlockchainAsset: Codable {
        let type: String
        let id: String
        let name: String
        let symbol: String
        let blockchain: Blockchain
        
        private enum CodingKeys: String, CodingKey {
            case type = "@type"
            case id
            case name
            case symbol
            case blockchain
        }
    }
    
    struct Blockchain: Codable {
        let id: String
        let name: String
        var networkId: Int?
    }

    struct SupportedBlockchainAssetsResponse: Codable {
        let items: [BlockchainAsset]
    }
}
