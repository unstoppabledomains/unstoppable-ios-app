//
//  WalletConnectServiceV2+Entities.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation

extension WalletConnectServiceV2 {
    struct ConnectionUISettings {
        let domain: DomainItem
        let blockchainType: BlockchainType
    }
    
    struct ConnectionConfig {
        let domain: DomainItem
        let appInfo: WCServiceAppInfo
    }
    
    enum Wc2ConnectionType {
        case oldPairing
        case newPairing (WalletConnectURI)
    }
    
    struct ConnectWalletRequest: Equatable {
        let uri: WalletConnectURI
    }
    
}

enum WalletConnectUIError: Error {
    case cancelled, noControllerToPresent
}

enum WCRequest {
    case connectWallet(_ request: WalletConnectServiceV2.ConnectWalletRequest),
         signMessage(_ request: SignMessageTransactionUIConfiguration),
         payment(_ request: SignPaymentTransactionUIConfiguration)
}
