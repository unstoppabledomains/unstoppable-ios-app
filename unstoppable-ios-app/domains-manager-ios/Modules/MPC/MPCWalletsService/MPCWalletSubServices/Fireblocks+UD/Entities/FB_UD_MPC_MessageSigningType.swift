//
//  FB_UD_MPC_MessageSigningType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.06.2024.
//

import Foundation

extension FB_UD_MPC {
    enum MessageSigningType {
        case personalSign(SignMessageEncoding)
        case typedData
    }
}
