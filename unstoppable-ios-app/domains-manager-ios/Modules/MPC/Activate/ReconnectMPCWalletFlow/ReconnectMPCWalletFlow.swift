//
//  ReconnectMPCWalletFlow.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2024.
//

import SwiftUI

enum ReconnectMPCWalletFlow { }

extension ReconnectMPCWalletFlow {
    typealias FlowResultCallback = (ReconnectMPCWalletFlow.FlowResult)->()
    
    enum FlowResult {
        case reconnected
        case removed
    }
    
    enum FlowAction {
        case removeWallet
        case reImportWallet
        case didEnterCredentials(MPCActivateCredentials)
        case didEnterCode(String)
        case didActivate(UDWallet)
        case didRequestToChangeEmail
    }
}
