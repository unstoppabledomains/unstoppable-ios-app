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
        let request = try getRequestForTransferDomain(domain,
                                                      to: receiverAddress,
                                                      configuration: configuration)
        let txIds = try await NetworkService().makeActionsAPIRequest(request,
                                                                     forDomain: domain,
                                                                     paymentConfirmationHandler: self)
        
        let domainName = domain.name
        var transactions = appContext.domainTransactionsService.getCachedTransactionsFor(domainNames: [domainName])
        let newTransactions = txIds.map({TransactionItem(id: $0.id,
                                                         transactionHash: nil,
                                                         domainName: domainName,
                                                         isPending: true,
                                                         operation: .transferDomain)})
        transactions.append(contentsOf: newTransactions)
        appContext.domainTransactionsService.cacheTransactions(transactions)
    }
}

// MARK: - Save records
private extension DomainTransferService {
    func getRequestForTransferDomain(_ domain: DomainItem,
                                     to receiverAddress: HexAddress,
                                     configuration: TransferDomainConfiguration) throws -> APIRequest {
        let request = try APIRequestBuilder()
            .actionPostTransferDomain(domain,
                                      to: receiverAddress,
                                      configuration: configuration)
            .build()
        return request
    }
}
