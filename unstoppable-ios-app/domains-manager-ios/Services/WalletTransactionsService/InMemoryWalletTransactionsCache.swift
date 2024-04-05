//
//  InMemoryWalletTransactionsCache.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

actor InMemoryWalletTransactionsCache: WalletTransactionsCacheProtocol {
    private var cache: [String: [WalletTransactionsPerChainResponse]] = [:]
    
    func fetchTransactionsFromCache(wallet: HexAddress) async -> [WalletTransactionsPerChainResponse]? {
        cache[wallet]
    }
    
    func setTransactionsToCache(_ txs: [WalletTransactionsPerChainResponse], for wallet: HexAddress) async {
        cache[wallet] = txs
    }
}
