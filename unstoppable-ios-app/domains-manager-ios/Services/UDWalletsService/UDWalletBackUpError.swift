//
//  UDWalletBackUpError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

enum UDWalletBackUpError: String, LocalizedError {
    case incorrectBackUpPassword
    case currentClusterNotSet
    case failedToMakePasswordHash
    case alreadyBackedUp
    
    public var errorDescription: String? {
        return rawValue
    }
}
