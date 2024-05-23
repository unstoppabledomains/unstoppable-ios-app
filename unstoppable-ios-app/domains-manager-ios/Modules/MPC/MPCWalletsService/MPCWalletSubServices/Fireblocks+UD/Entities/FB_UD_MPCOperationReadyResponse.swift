//
//  FB_UD_MPCOperationReadyResponse.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2024.
//

import Foundation

extension FB_UD_MPC {
    
    enum OperationReadyResponse {
        case txReady(txId: String)
        case signed(signature: String)
    }
    
}
