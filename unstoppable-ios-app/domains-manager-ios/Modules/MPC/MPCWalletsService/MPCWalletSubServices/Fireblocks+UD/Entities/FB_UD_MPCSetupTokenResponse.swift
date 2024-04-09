//
//  MPCSetupTokenResponse.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

extension FB_UD_MPC {
    struct SetupTokenResponse: Decodable {
        let transactionId: String // temp access token
        let status: String // 'QUEUED' | 'PENDING_SIGNATURE' | 'COMPLETED' | 'UNKNOWN';
        
        var isReady: Bool { status == "PENDING_SIGNATURE" }
    }
}
