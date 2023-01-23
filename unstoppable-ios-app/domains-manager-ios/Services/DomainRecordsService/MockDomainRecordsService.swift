//
//  MockDomainRecordsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.05.2022.
//

import Foundation

final class MockDomainRecordsService {
    
}

// MARK: - DomainRecordsServiceProtocol
extension MockDomainRecordsService: DomainRecordsServiceProtocol {
    func getRecordsFor(domain: DomainItem) async throws -> DomainRecordsData {
        let coins = await appContext.coinRecordsService.getCurrencies()
        let records = coins.map({ CryptoRecord.init(coin: $0) })
        return.init(records: [], resolver: nil, ipfsRedirectUrl: nil)
    }
    
    func saveRecords(records: [RecordToUpdate], in domain: DomainItem, paymentConfirmationDelegate: PaymentConfirmationDelegate) async throws { }
    
    func fetchAllTransactionsFor(domains: [DomainItem]) async throws -> [TransactionItem] {
        []
    }
}
