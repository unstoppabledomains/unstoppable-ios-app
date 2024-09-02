//
//  ActivateMPCWalletFlow.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.04.2024.
//

import Foundation

enum ActivateMPCWalletFlow { }

extension ActivateMPCWalletFlow {
    enum FlowAction {
        case didEnterCredentials(MPCActivateCredentials)
        case didPressForgotPassword
        case didEnterCode(String)
        case didActivate(UDWallet)
        case didRequestToChangeEmail
    }
    
    typealias FlowResultCallback = (ActivateMPCWalletFlow.FlowResult)->()
    
    enum FlowResult {
        case activated(UDWallet)
    }
    
    static let viewsTopOffset: CGFloat = 30
}


