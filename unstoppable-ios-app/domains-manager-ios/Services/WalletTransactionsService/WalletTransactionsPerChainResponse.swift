//
//  TransactionsPerChainResponse.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

struct WalletTransactionsPerChainResponse: Codable {
    let chain: String
    let cursor: String?
    let txs: [SerializedWalletTransaction]
    
    func resolveBlockchainType() -> BlockchainType? {
        try? BlockchainType.resolve(shortCode: chain)
    }
}
