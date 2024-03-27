//
//  WalletTransactionsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

final class WalletTransactionsService {

    private let networkService: WalletTransactionsNetworkServiceProtocol
    private var cache: WalletTransactionsCacheProtocol

    init(networkService: WalletTransactionsNetworkServiceProtocol,
         cache: WalletTransactionsCacheProtocol) {
        self.networkService = networkService
        self.cache = cache
    }
   
}

// MARK: - WalletTransactionsServiceProtocol
extension WalletTransactionsService: WalletTransactionsServiceProtocol {
    func getTransactionsFor(wallet: HexAddress, forceReload: Bool) async throws -> WalletTransactionsResponse {
        if !forceReload, let cachedResponse = await cache.fetchTransactionsFromCache(wallet: wallet) {
            var response: [WalletTransactionsPerChainResponse] = []
            if cachedResponse.hasAnyToLoadMore() {
                response = try await fetchAndCacheMoreTransactions(for: wallet, responses: cachedResponse)
            } else {
                response = cachedResponse
            }
            return WalletTransactionsResponse(canLoadMore: response.hasAnyToLoadMore(),
                                        txs: response.combinedTxs())
        } else {
            let newResponse = try await fetchAndCacheTransactions(for: wallet, cursor: nil, chain: nil, forceReload: true)
            return WalletTransactionsResponse(canLoadMore: newResponse.hasAnyToLoadMore(),
                                        txs: newResponse.combinedTxs())
        }
    }
}

// MARK: - Private methods
private extension WalletTransactionsService {
    func fetchAndCacheMoreTransactions(for wallet: HexAddress, responses: [WalletTransactionsPerChainResponse]) async throws -> [WalletTransactionsPerChainResponse] {
        var result: [WalletTransactionsPerChainResponse] = []
        
        try await withThrowingTaskGroup(of: [WalletTransactionsPerChainResponse].self) { group in
            for response in responses {
                if let cursor = response.cursor {
                    group.addTask {
                        try await self.fetchAndCacheTransactions(for: wallet, cursor: response.cursor, chain: response.chain, forceReload: false)
                    }
                } else {
                    result.append(response)
                }
            }
            
            for try await response in group {
                result.append(contentsOf: response.compactMap { $0 })
            }
        }
        
        return result
    }
    
    func fetchAndCacheTransactions(for wallet: HexAddress, cursor: String?, chain: String?, forceReload: Bool) async throws -> [WalletTransactionsPerChainResponse] {
        let newResponse = try await fetchTransactions(for: wallet, cursor: cursor, chain: chain, forceRefresh: forceReload)
        if forceReload {
            await cache.setTransactionsToCache(newResponse, for: wallet)
            return newResponse
        } else {
            let finalResult = await mergeResponsesWithLocalCache(newResponse, for: wallet)
            return finalResult
        }
    }
    
    func fetchTransactions(for wallet: HexAddress, 
                           cursor: String?,
                           chain: String?,
                           forceRefresh: Bool) async throws -> [WalletTransactionsPerChainResponse] {
        try await networkService.getTransactionsFor(wallet: wallet, cursor: cursor, chain: chain, forceRefresh: forceRefresh)
    }
    
    func mergeResponsesWithLocalCache(_ newResponses: [WalletTransactionsPerChainResponse], for wallet: HexAddress) async -> [WalletTransactionsPerChainResponse] {
        var finalResponses: [WalletTransactionsPerChainResponse] = []
        let existingResponse = await cache.fetchTransactionsFromCache(wallet: wallet) ?? []
        for newResponse in newResponses {
            if let index = existingResponse.firstIndex(where: { $0.chain == newResponse.chain }) {
                // Merge transactions only if the response exists in cache
                let existingTxs = existingResponse[index].txs
                let newTxs = newResponse.txs.filter { newTx in
                    !existingTxs.contains(where: { $0.id == newTx.id })
                }
                let mergedTxs = existingTxs + newTxs
                let finalResponse = WalletTransactionsPerChainResponse(chain: newResponse.chain, cursor: newResponse.cursor, txs: mergedTxs)
                finalResponses.append(finalResponse)
            } else {
                // If response does not exist, add it to the cache
                finalResponses.append(newResponse)
            }
        }
        await cache.setTransactionsToCache(finalResponses, for: wallet)
        return finalResponses
    }
}

private extension Array where Element == WalletTransactionsPerChainResponse {
    func hasAnyToLoadMore() -> Bool {
        first(where: { $0.cursor != nil }) != nil
    }
    
    func combinedTxs() -> [SerializedWalletTransaction] {
        flatMap({ $0.txs })
    }
}
