//
//  FireblocksRPCMessageHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import Foundation

final class FireblocksBootstrapRPCMessageHandler: FireblocksRPCMessageHandler, FireblocksConnectorMessageHandler {
    
    let authToken: String
    let networkService = NetworkService()
    
    init(authToken: String) {
        self.authToken = authToken
    }
    
    func handleOutgoingMessage(payload: String,
                               response: @escaping (String?) -> (),
                               error: @escaping (String?) -> ()) {
        passRPC(payload: payload,
                authToken: authToken,
                response: response,
                error: error)
    }
    
}
