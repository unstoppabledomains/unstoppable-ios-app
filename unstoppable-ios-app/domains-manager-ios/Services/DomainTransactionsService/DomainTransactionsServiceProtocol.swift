//
//  DomainTransactionsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.05.2022.
//

import Foundation

protocol DomainTransactionsServiceProtocol {
    func getCachedTransactionsFor(domainNames: [String]) -> [TransactionItem]
    func cacheTransactions(_ transactions: [TransactionItem])
    func updatePendingTransactionsListFor(domains: [String]) async throws -> [TransactionItem]
}
