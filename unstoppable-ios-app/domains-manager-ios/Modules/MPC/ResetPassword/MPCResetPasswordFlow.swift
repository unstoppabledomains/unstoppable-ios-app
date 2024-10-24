//
//  MPCResetPasswordFlow.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.10.2024.
//

import Foundation

enum MPCResetPasswordFlow { }

extension MPCResetPasswordFlow {
    enum FlowAction {
        case didEnterNewPassword(String)
        case didEnterCode(String)
        case didActivate(UDWallet)
    }
    
    typealias FlowResultCallback = (MPCResetPasswordFlow.FlowResult)->()

    enum FlowResult {
        case restored(UDWallet)
    }
    
    struct ResetPasswordFullData: Hashable {
        let resetPasswordData: MPCResetPasswordData
        let newPassword: String
        let code: String
    }
}
