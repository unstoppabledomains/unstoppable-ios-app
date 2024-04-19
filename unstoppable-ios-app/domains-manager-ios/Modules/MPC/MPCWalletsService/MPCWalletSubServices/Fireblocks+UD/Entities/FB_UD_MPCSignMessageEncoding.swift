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
    struct OperationDetails: Codable {
        let id: String
        let status: String
        let type: String
    }
}
