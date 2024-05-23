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
}
