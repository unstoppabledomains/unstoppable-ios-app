//
//  TestableDomainTransactionsService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import Foundation
@testable import domains_manager_ios

final class TestableDomainTransactionsService: DomainTransactionsServiceProtocol {
    func getCachedTransactionsFor(domainNames: [String]) -> [TransactionItem] {
        []
    }
    
    func cacheTransactions(_ transactions: [TransactionItem]) {
        
    }
    
    func updatePendingTransactionsListFor(domains: [String]) async throws -> [TransactionItem] {
        []
    }
    
    
}
