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
            String.Constants.wrongPasscode.localized()
        case .incorrectPassword:
            String.Constants.wrongPassword.localized()
        case .unknown:
            String.Constants.somethingWentWrong.localized()
        }
    }
    
    var actionTitle: String {
        switch self {
        case .incorrectPasscode:
            String.Constants.reEnterPasscode.localized()
        case .incorrectPassword:
            String.Constants.reEnterPassword.localized()
        case .unknown:
            String.Constants.tryAgain.localized()
        }
    }
}
