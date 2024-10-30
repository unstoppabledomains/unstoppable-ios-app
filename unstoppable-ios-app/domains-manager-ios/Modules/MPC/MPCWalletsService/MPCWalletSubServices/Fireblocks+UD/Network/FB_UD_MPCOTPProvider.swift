//
//  FB_UD_MPCOTPProvider.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.10.2024.
//

import Foundation

extension FB_UD_MPC {
    protocol MPCOTPProvider {
        func getMPCOTP() async throws -> String
    }
}
