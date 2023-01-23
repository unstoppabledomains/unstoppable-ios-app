//
//  WalletDataValidator.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import Foundation

protocol WalletDataValidator {
    func isNameValid(_ name: String, for wallet: WalletDisplayInfo) -> Result<Void, WalletNameValidationError>
    func isBackupPasswordValid(_ password: String) -> Result<Void, WalletBackupPasswordValidationError>
}

extension WalletDataValidator {
    func isNameValid(_ name: String, for wallet: WalletDisplayInfo) -> Result<Void, WalletNameValidationError> {
        let name = name.trimmedSpaces
        if name.isEmpty {
            return .failure(.empty)
        } else if name.count > 24 {
            return .failure(.tooLong)
        } else if let walletWithSameName = UDWalletsStorage.instance.getWallet(byName: name),
                  walletWithSameName.address != wallet.address {
            return .failure(.notUnique(walletName: wallet.walletSourceName))
        }
        return .success(Void())
    }
    
    func isBackupPasswordValid(_ password: String) -> Result<Void, WalletBackupPasswordValidationError> {
        if password.isEmpty {
            return .failure(.empty)
        }
        
        if password.count < 8 {
            return .failure(.tooSmall)
        }
        
        if !password.hasDecimalDigit {
            return .failure(.noDigits)
        }
        
        if !password.hasLetters {
            return .failure(.noLetters)
        }
        
        if password.count > 30 {
            return .failure(.tooBig)
        }
        
        return .success(Void())
    }
}

enum WalletNameValidationError: Error, Equatable {
    case empty, tooLong, notUnique(walletName: String)
    
    var message: String? {
        switch self {
        case .empty: return nil
        case .tooLong: return String.Constants.walletNameTooLongError.localized()
        case .notUnique(let walletName): return String.Constants.walletNameNotUniqueError.localized(walletName)
        }
    }
    
    static func == (lhs: WalletNameValidationError, rhs: WalletNameValidationError) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case (.tooLong, .tooLong):
            return true
        case (.notUnique, .notUnique):
            return true
        default:
            return false
        }
    }
}

enum WalletBackupPasswordValidationError: Error {
    case empty, tooSmall, noDigits, noLetters, tooBig
    
    var message: String {
        switch self {
        case .empty: return String.Constants.passwordRuleAtLeast.localized()
        case .tooSmall: return String.Constants.passwordRuleCharacters.localized()
        case .noDigits: return String.Constants.passwordRuleNumber.localized()
        case .noLetters: return String.Constants.passwordRuleLetter.localized()
        case .tooBig: return String.Constants.passwordRuleRange.localized()
        }
    }
}
