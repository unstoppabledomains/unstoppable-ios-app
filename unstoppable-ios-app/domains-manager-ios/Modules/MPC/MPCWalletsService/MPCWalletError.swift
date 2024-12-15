//
//  MPCWalletError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import Foundation

enum MPCWalletError: String, LocalizedError {
    case incorrectCode
    case incorrectPassword
    case messageSignDisabled
    case maintenanceEnabled
    case wrongRecoveryPassword
    
    public var errorDescription: String? {
        return rawValue
    }
}
