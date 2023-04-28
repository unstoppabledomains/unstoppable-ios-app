//
//  DomainRecordsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import Foundation

// MARK: - DomainRecordsServiceProtocol
final class DomainRecordsService: DomainRecordsServiceProtocol {
    func getRecordsFor(domain: DomainItem) async throws -> DomainRecordsData {
        let start = Date()
        let domainRecordsData = try await NetworkService().fetchRecords(domain: domain)
        Debugger.printWarning("\(String.itTook(from: start)) to load \(domainRecordsData.records.count) domain records for \(domain.name) domain")
        return domainRecordsData
    }
    
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
