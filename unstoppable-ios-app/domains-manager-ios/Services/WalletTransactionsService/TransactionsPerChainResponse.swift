//
//  TransactionsPerChainResponse.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

struct TransactionsPerChainResponse: Codable {
    let chain: String
    let cursor: String?
    let txs: [SerializedWalletTransaction]
}
