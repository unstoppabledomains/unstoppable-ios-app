//
//  PreviewDomainTransactionsService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

final class DomainTransactionsService: DomainTransactionsServiceProtocol {
    func getCachedTransactionsFor(domainNames: [String]) -> [TransactionItem] {
        []
    }
    
    func cacheTransactions(_ transactions: [TransactionItem]) {
        
    }
    
    func updatePendingTransactionsListFor(domains: [String]) async throws -> [TransactionItem] {
        []
    }
    
    func pendingTxsExistFor(domain: DomainItem) async throws -> Bool {
        false
    }
    
    
}

