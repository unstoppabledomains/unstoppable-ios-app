//
//  FB_UD_MPCSignMessageEncoding.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.04.2024.
//

import Foundation

extension FB_UD_MPC {
    enum SignMessageEncoding: String, Codable {
        case utf8, hex
    }
}

extension FB_UD_MPC {
    struct OperationDetails: Codable, TransactionOperation {
        let id: String
        let status: String
        let type: String
        var transaction: Transaction?
        var result: Result?
        
        struct Transaction: Codable {
            let externalVendorTransactionId: String?
        }
        
        struct Result: Codable {
            let signature: String?
        }
    }
}
