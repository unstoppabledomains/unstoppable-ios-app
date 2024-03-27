//
//  WalletTransactionsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

final class WalletTransactionsService {

    private let networkService: WalletTransactionsNetworkServiceProtocol
    private var cache = TransactionsCache()

    init(networkService: WalletTransactionsNetworkServiceProtocol) {
        self.networkService = networkService
    }
   
}

// MARK: - WalletTransactionsServiceProtocol
extension WalletTransactionsService: WalletTransactionsServiceProtocol {
    func getTransactionsFor(wallet: HexAddress, forceReload: Bool) async throws -> TransactionsResponse {
        if !forceReload, let cachedResponse = await cache.fetchTransactionsFromCache(wallet: wallet) {
            // Use cached response if forceReload is false and cache exists
            return TransactionsResponse(canLoadMore: cachedResponse.hasAnyToLoadMore(), 
                                        txs: cachedResponse.combinedTxs())
        } else {
            // Fetch new transactions
            let newResponse = try await fetchTransactions(for: wallet, cursor: nil, chain: nil)
            // Merge with existing cache
            await mergeResponses(newResponse, for: wallet)
            return TransactionsResponse(canLoadMore: newResponse.hasAnyToLoadMore(),
                                        txs: newResponse.combinedTxs())
        }
    }
}

// MARK: - Private methods
private extension WalletTransactionsService {
    func fetchTransactions(for wallet: HexAddress, cursor: String?, chain: String?) async throws -> [TransactionsPerChainResponse] {
        try await networkService.getTransactionsFor(wallet: wallet, cursor: cursor, chain: chain)
    }
    
    func mergeResponses(_ newResponses: [TransactionsPerChainResponse], for wallet: HexAddress) async {
        var finalResponses: [TransactionsPerChainResponse] = []
        let existingResponse = await cache.fetchTransactionsFromCache(wallet: wallet) ?? []
        for newResponse in newResponses {
            if let index = existingResponse.firstIndex(where: { $0.chain == newResponse.chain }) {
                // Merge transactions only if the response exists in cache
                let existingTxs = existingResponse[index].txs
                let newTxs = newResponse.txs.filter { newTx in
                    !existingTxs.contains(where: { $0.id == newTx.id })
                }
                let mergedTxs = existingTxs + newTxs
                let finalResponse = TransactionsPerChainResponse(chain: newResponse.chain, cursor: newResponse.cursor, txs: mergedTxs)
                finalResponses.append(finalResponse)
            } else {
                // If response does not exist, add it to the cache
                finalResponses.append(newResponse)
            }
        }
        await cache.setTransactionsToCache(finalResponses, for: wallet)
    }
}

// MARK: - Private methods
private extension WalletTransactionsService {
    actor TransactionsCache {
        private var cache: [String: [TransactionsPerChainResponse]] = [:]
        
        func fetchTransactionsFromCache(wallet: HexAddress) async -> [TransactionsPerChainResponse]? {
            cache[wallet]
        }
        
        func setTransactionsToCache(_ txs: [TransactionsPerChainResponse], for wallet: HexAddress) async {
            cache[wallet] = txs
        }
    }
}

private extension Array where Element == TransactionsPerChainResponse {
    func hasAnyToLoadMore() -> Bool {
        first(where: { $0.cursor != nil }) != nil
    }
    
    func combinedTxs() -> [SerializedWalletTransaction] {
        flatMap({ $0.txs })
    }
}

struct TransactionsResponse {
    let canLoadMore: Bool
    let txs: [SerializedWalletTransaction]
}
