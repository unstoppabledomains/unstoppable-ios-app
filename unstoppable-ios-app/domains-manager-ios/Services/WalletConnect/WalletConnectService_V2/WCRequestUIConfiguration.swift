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

// MARK: - Open methods
extension WCRequestUIConfiguration {
    static func mockSign() -> WCRequestUIConfiguration {
        .signMessage(.init(connectionConfig: .init(domain: .init(name: "oleg.x", ownerWallet: "123", blockchain: .Ethereum),
                                                   appInfo: .init()),
                           signingMessage: "123"))
    }
    
    static func mockConnect() -> WCRequestUIConfiguration {
        .connectWallet(.init(domain: .init(name: "oleg.x", ownerWallet: "123", blockchain: .Ethereum), appInfo: .init()))
    }
}
