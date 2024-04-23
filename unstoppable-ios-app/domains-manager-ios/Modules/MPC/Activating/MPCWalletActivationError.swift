//
//  MPCWalletActivationError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.04.2024.
//

import Foundation

enum MPCWalletActivationError {
    case incorrectPassword
    case incorrectPasscode
    case unknown
    
    var title: String {
        switch self {
        case .incorrectPasscode:
            "Wrong passcode"
        case .incorrectPassword:
            "Wrong password"
        case .unknown:
            String.Constants.somethingWentWrong.localized()
        }
    }
    
    var actionTitle: String {
        switch self {
        case .incorrectPasscode:
            "Re-enter passcode"
        case .incorrectPassword:
            "Re-enter password"
        case .unknown:
            String.Constants.tryAgain.localized()
        }
    }
}
