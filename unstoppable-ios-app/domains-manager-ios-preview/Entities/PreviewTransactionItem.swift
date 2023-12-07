//
//  PreviewTransactionItem.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

struct TransactionItem: Codable {
    static let cnsConfirmationBlocksBLOCKS: UInt64 = 12
    var id: UInt64?
    var transactionHash: HexAddress?
    var domainName: String?
    var isPending: Bool = false
    var operation: TxOperation?

    func isMintingTransaction() -> Bool {   
        false
    }
}

extension Array where Element == TransactionItem {
    func containPending(_ domain: DomainItem) -> Bool {
        false
    }
    
    func filterPending(extraCondition: ( (TransactionItem) -> Bool) = { _ in true }) -> Self {
        self.filter({ $0.isPending && extraCondition($0) })
    }
}
