//
//  MPCActivateWalletEnterDataType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.04.2024.
//

import Foundation

enum MPCActivateWalletEnterDataType: String, Hashable, Identifiable {
    var id: String { rawValue }
    
    case passcode
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
