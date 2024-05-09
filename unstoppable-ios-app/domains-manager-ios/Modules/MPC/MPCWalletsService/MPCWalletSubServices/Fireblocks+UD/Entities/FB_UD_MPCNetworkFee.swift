//
//  FB_UD_MPCNetworkFee.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.05.2024.
//

import Foundation

extension FB_UD_MPC {
    struct NetworkFee: Codable {
        let amount: String
        let asset: WalletAccountAsset
    }
    
    struct NetworkFeeResponse: Codable {
        let priority: String // MEDIUM
        let status: String // VALID, INSUFFICIENT_FUNDS, INSUFFICIENT_FEE_FUNDS (dont have enough native tokens)
        let networkFee: NetworkFee?
    }
}
