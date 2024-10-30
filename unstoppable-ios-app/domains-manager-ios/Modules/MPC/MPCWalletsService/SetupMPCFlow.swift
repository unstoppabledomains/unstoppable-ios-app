//
//  SetupMPCFlow.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.10.2024.
//

import Foundation

enum SetupMPCFlow {
    case activate(MPCActivateCredentials)
    case resetPassword(MPCResetPasswordData, newPassword: String)
    
    var email: String {
        switch self {
        case .activate(let credentials): return credentials.email
        case .resetPassword(let data, _): return data.email
        }
    }
    
    var password: String {
        switch self {
        case .activate(let credentials): return credentials.password
        case .resetPassword(_, let newPassword): return newPassword
        }
    }
}
