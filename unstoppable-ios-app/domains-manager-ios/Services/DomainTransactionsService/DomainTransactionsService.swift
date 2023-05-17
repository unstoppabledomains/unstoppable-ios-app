//
//  DomainTransactionsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.05.2022.
//

import Foundation

final class DomainTransactionsService {
    private let storage: Storage = Storage.instance
    private lazy var txsFetcherFactory: TxsFetcherFactoryProtocol = DefaultTxsFetcherFactory()
}

// MARK: - DomainTransactionsServiceProtocol
extension DomainTransactionsService: DomainTransactionsServiceProtocol {
    func getCachedTransactionsFor(domainNames: [String]) -> [TransactionItem] {
        storage.getCachedTransactionsListSync(by: domainNames)
    }
    
    func cacheTransactions(_ transactions: [TransactionItem]) {
        storage.injectTxsUpdate_Blocking(transactions)
    }
    
    func updateTransactionsListFor(domains: [String]) async throws -> [TransactionItem] {
        let start = Date()
        let transactions = try await txsFetcherFactory.createFetcher().fetchAllTxs(for: domains)
        Debugger.printTimeSensitiveInfo(topic: .Transactions,
                                        "to load \(transactions.count) transactions for \(domains.count) domains",
                                        startDate: start,
                                        timeout: 2)
        storage.injectTxsUpdate_Blocking(transactions)
        return transactions
    }
    
    func pendingTxsExistFor (domain: DomainItem) async throws -> Bool {
        let transactions = try await updateTransactionsListFor(domains: [domain.name])
        return transactions.containPending(domain)
    }
}


protocol TxsFetcherFactoryProtocol {
    func createFetcher() -> TxsFetcher
}

struct DefaultTxsFetcherFactory: TxsFetcherFactoryProtocol {
    func createFetcher() -> TxsFetcher {
        return NetworkService()
    }
}
