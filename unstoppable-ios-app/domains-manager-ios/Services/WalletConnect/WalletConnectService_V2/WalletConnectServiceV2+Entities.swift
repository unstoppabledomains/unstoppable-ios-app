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
}
