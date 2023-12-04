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
    
}
