//
//  FB_UD_MPCRefreshBootstrapTokenResponse.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.04.2024.
//

import Foundation

extension FB_UD_MPC {
    struct RefreshBootstrapTokenResponse: Decodable {
        let accessToken: String
        let deviceId: String
    }
}

