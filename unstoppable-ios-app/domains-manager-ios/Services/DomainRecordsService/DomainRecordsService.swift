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
        try await saveRecordsWithPayment(in: domain,
                                         paymentConfirmationDelegate: paymentConfirmationDelegate,
                                         with: records)
    }
}

// MARK: - Save records
private extension DomainRecordsService {
    func saveRecordsWithPayment(in domain: DomainItem,
                                paymentConfirmationDelegate: PaymentConfirmationDelegate,
                                with records: [RecordToUpdate]) async throws {
        let request = try getRequestForActionUpdateRecords(domain, records: records)
        let actionsResponse = try await NetworkService().getActions(request: request)
        let blockchain = try BlockchainType.getType(abbreviation: actionsResponse.domain.blockchain)
        
        let payloadReturned: NetworkService.TxPayload
        if let paymentInfo = actionsResponse.paymentInfo {
            let payloadFormed = try DomainItem.createTxPayload(blockchain: blockchain, paymentInfo: paymentInfo, txs: actionsResponse.txs)
            payloadReturned = try await paymentConfirmationDelegate.fetchPaymentConfirmationAsync(for: domain, payload: payloadFormed)
        } else {
            let messages = actionsResponse.txs.compactMap { $0.messageToSign }
            guard messages.count == actionsResponse.txs.count else { throw NetworkLayerError.noMessageError }
            payloadReturned = NetworkService.TxPayload(messages: messages, txCost: nil)
        }
        
        let signatures: [String] = try await UDWallet.createSignaturesByEthSign(messages: payloadReturned.messages, domain: domain)

        let requestSign = try NetworkService.getRequestForActionSign(id: actionsResponse.id,
                                                         response: actionsResponse,
                                                           signatures: signatures)
        try await NetworkService().postMetaActions(requestSign)
    }
    
    
    private func getRequestForActionUpdateRecords(_ domain: DomainItem, records: [RecordToUpdate]) throws -> APIRequest {
        let request = try APIRequestBuilder()
            .actionPostUpdateRecords(for: domain, records: records)
            .build()
        return request
    }
}
