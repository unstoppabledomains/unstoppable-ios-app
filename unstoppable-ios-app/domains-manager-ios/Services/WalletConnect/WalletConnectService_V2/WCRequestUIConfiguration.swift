//
//  WCRequestUIConfiguration.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation

enum WCRequestUIConfiguration {
    case signMessage(_ configuration: SignMessageTransactionUIConfiguration),
         payment(_ configuration: SignPaymentTransactionUIConfiguration),
         connectWallet(_ configuration: WalletConnectServiceV2.ConnectionConfig)
    
    var isSARequired: Bool {
        switch self {
        case .connectWallet:
            return false
        case .signMessage, .payment:
            return true
        }
    }
}

