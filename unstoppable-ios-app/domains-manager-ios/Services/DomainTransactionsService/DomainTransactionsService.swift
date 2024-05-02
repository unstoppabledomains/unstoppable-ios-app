//
//  DomainTransactionsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.05.2022.
//

import Foundation

final class DomainTransactionsService {
    private let storage: Storage = Storage.instance
}

// MARK: - DomainTransactionsServiceProtocol
extension DomainTransactionsService: DomainTransactionsServiceProtocol {
    func getCachedTransactionsFor(domainNames: [String]) -> [TransactionItem] {
        storage.getCachedTransactionsListSync(by: domainNames)
    }
    
    func cacheTransactions(_ transactions: [TransactionItem]) {
        storage.injectTxsUpdate_Blocking(transactions)
    }
    
    func updatePendingTransactionsListFor(domains: [DomainItem]) async throws -> [TransactionItem] {
        let start = Date()
        var transactions: [TransactionItem] = []
        
        try await withThrowingTaskGroup(of: [TransactionItem].self) { group in
            for domain in domains {
                group.addTask {
                    try await NetworkService().fetchPendingTxsFor(domain: domain)
                }
            }
            
            for try await txs in group {
                transactions.append(contentsOf: txs)
            }
        }
        Debugger.printTimeSensitiveInfo(topic: .Network,
                                        "to load \(transactions.count) transactions for \(domains.count) domains",
                                        startDate: start,
                                        timeout: 2)
        storage.replaceTxs_Blocking(transactions)
        return transactions
    }
}
