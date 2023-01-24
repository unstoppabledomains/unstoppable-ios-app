//
//  MockDomainTransactionsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.05.2022.
//

import Foundation

final class MockDomainTransactionsService {
    private lazy var mintingTransactions: [TransactionItem] = {
        [.init(transactionHash: "123", domainName: "coolguy.crypto", isPending: true, operation: .mintDomain),
         .init(transactionHash: "234", domainName: "joshgordon_4.crypto", isPending: true, operation: .mintDomain)]
    }()
}

// MARK: - DomainTransactionsServiceProtocol
extension MockDomainTransactionsService: DomainTransactionsServiceProtocol {
    func pendingTxsExistFor(domain: DomainItem) async throws -> Bool {
        return !mintingTransactions.filterPending(extraCondition: {domain.name == $0.domainName}).isEmpty
    }
    
    func getCachedTransactionsFor(domainNames: [String]) -> [TransactionItem] { [] }
    func cacheTransactions(_ transactions: [TransactionItem]) { }
    func updateTransactionsListFor(domains: [String]) async throws -> [TransactionItem] {
        domains.map({
            TransactionItem(transactionHash: UUID().uuidString,
                            domainName: $0,
                            isPending: true,
                            operation: .mintDomain)
        })
    }
}
