//
//  WCRegistryWalletProxy.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

struct WCRegistryWalletProxy {
    let host: String
    let name: String
    
    // TODO: Remove when Ledger fixes the url in wallet info
    var needsLedgerSearchHack: Bool {
        name.lowercased().contains("ledger")
    }
    
    init?(_ walletInfo: SessionV2) {
        guard let url = URL(string: walletInfo.peer.url),
              let host = url.host else { return nil }
        self.host = host
        self.name = walletInfo.peer.name
    }
}
