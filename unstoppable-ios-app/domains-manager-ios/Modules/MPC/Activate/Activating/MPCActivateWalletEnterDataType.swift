//
//  MPCActivateWalletEnterDataType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.04.2024.
//

import Foundation

enum MPCActivateWalletEnterDataType: Identifiable {
    var id: String {
        switch self {
        case .passcode:
            return "passcode"
        case .password:
            return "password"
        }
    }
    
    case passcode(ResendConfirmationCodeBlock)
    case password
    
    var analyticsName: Analytics.ViewName {
        switch self {
        case .passcode:
                .mpcActivateEnterCode
        case .password:
                .mpcActivateEnterPassword
        }
    }
}
