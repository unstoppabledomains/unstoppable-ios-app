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
        case didEnterCode(String)
        case didActivate
        case didRequestToChangeEmail
    }
    
    static let viewsTopOffset: CGFloat = 30
}

