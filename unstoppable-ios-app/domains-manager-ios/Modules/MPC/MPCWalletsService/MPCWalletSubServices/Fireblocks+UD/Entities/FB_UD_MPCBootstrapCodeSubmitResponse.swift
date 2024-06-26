//
//  MPCBootstrapCodeSubmitResponse.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

extension FB_UD_MPC {
    struct BootstrapCodeSubmitResponse: Decodable {
        let accessToken: String // temp access token
        let deviceId: String
    }
}
