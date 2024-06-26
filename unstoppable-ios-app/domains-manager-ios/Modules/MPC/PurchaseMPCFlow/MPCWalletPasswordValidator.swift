//
//  MPCWalletPasswordValidator.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.05.2024.
//

import Foundation

protocol MPCWalletPasswordValidator {
    func validateWalletPassword(_ password: String) -> [MPCWalletPasswordValidationError]
}

extension MPCWalletPasswordValidator {
    var minMPCWalletPasswordLength: Int { 12 }
    var maxMPCWalletPasswordLength: Int { 32 }
    var mpcWalletPasswordSpecialCharacterRegex: NSRegularExpression { try! NSRegularExpression(pattern: "[!@#$%^&*()_+\\-\\[\\]{};':\"\\\\|,.<>\\/?]+") }
    
    func validateWalletPassword(_ password: String) -> [MPCWalletPasswordValidationError] {
        let minLength = minMPCWalletPasswordLength
        let maxLength = maxMPCWalletPasswordLength
        let numberRegex = try! NSRegularExpression(pattern: "\\d")
        
        var errors: [MPCWalletPasswordValidationError] = []
        
        if password.count < minLength {
            errors.append(.tooShort)
        }
        
        if password.count >= maxLength {
            errors.append(.tooLong)
        }
        
        if numberRegex.firstMatch(in: password, range: NSRange(location: 0, length: password.utf16.count)) == nil {
            errors.append(.missingNumber)
        }
        
        if mpcWalletPasswordSpecialCharacterRegex.firstMatch(in: password, range: NSRange(location: 0, length: password.utf16.count)) == nil {
            errors.append(.missingSpecialCharacter)
        }
        
        return errors
    }
}

enum MPCWalletPasswordValidationError: String, LocalizedError {
    case tooShort
    case tooLong
    case missingNumber
    case missingSpecialCharacter

    public var errorDescription: String? {
        rawValue
    }
}
