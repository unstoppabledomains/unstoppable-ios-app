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
                     paymentConfirmationHandler: PaymentConfirmationHandler) async throws {
        try await NetworkService().manageDomain(domain: domain, type: .updateRecords(records))
    }
}
