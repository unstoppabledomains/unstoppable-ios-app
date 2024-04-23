//
//  MPCSetupTokenResponse.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

extension FB_UD_MPC {
    struct SetupTokenResponse: Decodable, TransactionOperation {
        let transactionId: String // temp access token
        let status: String
    }
}

extension FB_UD_MPC {
    protocol TransactionOperation {
        var status: String { get }
        
        var isReady: Bool { get }
    }
    
    enum TransactionOperationStatus: String {
        case queued = "QUEUED"
        case pendingSignature = "PENDING_SIGNATURE"
        case signatureRequired = "SIGNATURE_REQUIRED"
        case completed = "COMPLETED"
        case unknown = "UNKNOWN"
    }
}

extension FB_UD_MPC.TransactionOperation {
    var isReady: Bool { status == FB_UD_MPC.TransactionOperationStatus.pendingSignature.rawValue }
}
