//
//  UserDataValidator.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.05.2022.
//

import Foundation

protocol UserDataValidator {
    func isEmailValid(_ email: String) -> Result<Void, EmailValidationError>
}

extension UserDataValidator {
    func isEmailValid(_ email: String) -> Result<Void, EmailValidationError> {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            return .failure(.invalidFormat)
        }

        return .success(Void())
    }
}

enum EmailValidationError: Error {
    case invalidFormat
    
    var message: String {
        switch self {
        case .invalidFormat: return ""
        }
    }
}
