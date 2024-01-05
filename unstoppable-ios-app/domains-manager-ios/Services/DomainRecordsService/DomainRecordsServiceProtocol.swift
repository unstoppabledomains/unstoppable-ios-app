//
//  DomainRecordsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import Foundation

protocol DomainRecordsServiceProtocol {
    func saveRecords(records: [RecordToUpdate],
                             in domain: DomainItem,
                             paymentConfirmationDelegate: PaymentConfirmationDelegate) async throws
}

enum DomainRecordsServiceFetchError: String, LocalizedError {
    case recordsFetchFailed
    case resolverFetchFailed
    
    public var errorDescription: String? {
        return rawValue
    }
}

enum DomainRecordsServiceSaveError: LocalizedError {
    case failedToBuildRequest
    case failedToCreateTXDetails
    case paymentError(_ paymentError: PaymentError)
    case saveError(_ error: Error)
    
    public var errorDescription: String? {
        switch self {
        case .failedToBuildRequest:
            return "Failed to build request"
        case .failedToCreateTXDetails:
            return "Failed to create TX Details"
        case .paymentError(let error):
            return "Payment error: \(error.localizedDescription)"
        case .saveError(let error):
            return "Save error: \(error.localizedDescription)"
        }
    }
}
