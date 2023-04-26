//
//  DomainTransferService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.04.2023.
//

import Foundation

final class DomainTransferService {
    
}

// MARK: - DomainTransferServiceProtocol
extension DomainTransferService: DomainTransferServiceProtocol {
    func transferDomain(domain: DomainItem,
                        to receiverAddress: HexAddress,
                        configuration: TransferDomainConfiguration,
                        paymentConfirmationDelegate: PaymentConfirmationDelegate) async throws {
        let request = try getRequestForTransferDomain(domain,
                                                      to: receiverAddress,
                                                      configuration: configuration)
        try await NetworkService().makeActionsAPIRequest(request,
                                                         forDomain: domain,
                                                         paymentConfirmationDelegate: paymentConfirmationDelegate)
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

struct TransferDomainConfiguration {
    let resetRecords: Bool
}
