//
//  DomainTransferService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.04.2023.
//

import Foundation

final class DomainTransferService: PaymentConfirmationHandler {
    
}

// MARK: - DomainTransferServiceProtocol
extension DomainTransferService: DomainTransferServiceProtocol {
    func transferDomain(domain: DomainItem,
                        to receiverAddress: HexAddress,
                        configuration: TransferDomainConfiguration) async throws {
        try await NetworkService().manageDomain(domain: domain, type: .transfer(transferToAddress: receiverAddress,
                                                                                configuration: configuration))
        
        let domainName = domain.name
        var transactions = appContext.domainTransactionsService.getCachedTransactionsFor(domainNames: [domainName])
        let newTransaction = TransactionItem(id: nil,
                                              transactionHash: UUID().uuidString,
                                              domainName: domainName,
                                              isPending: true,
                                              operation: .transferDomain)
        transactions.append(contentsOf: [newTransaction])
        appContext.domainTransactionsService.cacheTransactions(transactions)
    }
}
