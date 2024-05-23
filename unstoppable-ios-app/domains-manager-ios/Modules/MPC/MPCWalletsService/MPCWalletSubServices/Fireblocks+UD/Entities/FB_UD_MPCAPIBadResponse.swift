//
//  FB_UD_MPCAPIBadResponse.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.05.2024.
//

import Foundation

extension FB_UD_MPC {
    struct APIBadResponse: Decodable {
        let code: String
    }
}
extension FB_UD_MPC.APIBadResponse {
    var isInvalidCodeResponse: Bool { code == "BAD_REQUEST" }
}
