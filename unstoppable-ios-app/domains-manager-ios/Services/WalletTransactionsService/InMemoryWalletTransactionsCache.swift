//
//  InMemoryWalletTransactionsCache.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

actor InMemoryWalletTransactionsCache: WalletTransactionsCacheProtocol {
    private var cache: [String: [TransactionsPerChainResponse]] = [:]
    
    func fetchTransactionsFromCache(wallet: HexAddress) async -> [TransactionsPerChainResponse]? {
        cache[wallet]
    }
    
    func setTransactionsToCache(_ txs: [TransactionsPerChainResponse], for wallet: HexAddress) async {
        cache[wallet] = txs
    }
}
