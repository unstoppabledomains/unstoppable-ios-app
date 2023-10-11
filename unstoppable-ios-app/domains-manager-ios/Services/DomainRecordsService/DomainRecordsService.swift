//
//  DomainRecordsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import Foundation

// MARK: - DomainRecordsServiceProtocol
final class DomainRecordsService: DomainRecordsServiceProtocol {
    
    func saveRecords(records: [RecordToUpdate],
                     in domain: DomainItem,
                     paymentConfirmationDelegate: PaymentConfirmationDelegate) async throws {
        let request = try getRequestForActionUpdateRecords(domain, records: records)
        try await NetworkService().makeActionsAPIRequest(request,
                                                         forDomain: domain,
                                                         paymentConfirmationDelegate: paymentConfirmationDelegate)
    }
}

// MARK: - Save records
private extension DomainRecordsService {
    func getRequestForActionUpdateRecords(_ domain: DomainItem,
                                          records: [RecordToUpdate]) throws -> APIRequest {
        let request = try APIRequestBuilder()
            .actionPostUpdateRecords(for: domain, records: records)
            .build()
        return request
    }
}
