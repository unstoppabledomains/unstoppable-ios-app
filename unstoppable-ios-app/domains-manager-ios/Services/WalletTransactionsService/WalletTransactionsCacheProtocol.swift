//
//  WalletTransactionsCacheProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

protocol WalletTransactionsCacheProtocol {
    func fetchTransactionsFromCache(wallet: HexAddress) async -> [TransactionsPerChainResponse]?
    func setTransactionsToCache(_ txs: [TransactionsPerChainResponse], for wallet: HexAddress) async
}
