//
//  JoinWalletHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import Foundation

final class JoinWalletHandler: FireblocksConnectorJoinWalletHandler {
    
    let requestIdCallback: (String) -> ()
    
    init(requestIdCallback: @escaping (String) -> ()) {
        self.requestIdCallback = requestIdCallback
    }
    
    func onRequestId(requestId: String) {
        requestIdCallback(requestId)
    }
}
