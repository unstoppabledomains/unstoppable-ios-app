//
//  FireblocksProxyWalletRPCMessageHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.04.2024.
//

import Foundation

/// Fireblocks instance created once per device id and can't be re-created or updated.
/// This creates issue of updating message handler after the bootstrap.
/// Proxy class used in Fireblocks instance and allows to update handler.
final class FireblocksProxyWalletRPCMessageHandler: FireblocksRPCMessageHandler, FireblocksConnectorMessageHandler {
    private var handler: FireblocksConnectorMessageHandler
    
    private init(handler: FireblocksConnectorMessageHandler) {
        self.handler = handler
    }
    
    private func updateHandler(_ handler: FireblocksConnectorMessageHandler) {
        self.handler = handler
    }
    
    func handleOutgoingMessage(payload: String,
                               response: @escaping (String?) -> (),
                               error: @escaping (String?) -> ()) {
        handler.handleOutgoingMessage(payload: payload, response: response, error: error)
    }
    
    
    static private var instances: [String : FireblocksProxyWalletRPCMessageHandler] = [:]
    static private let queue = DispatchQueue(label: "com.fireblocks.proxy.serial")
    
    @discardableResult
    static func createOrUpdateInstanceFor(deviceId: String, withHandler handler: FireblocksConnectorMessageHandler) -> FireblocksProxyWalletRPCMessageHandler {
        queue.sync {
            if let instance = instances[deviceId] {
                instance.updateHandler(handler)
                return instance
            } else {
                let newInstance = FireblocksProxyWalletRPCMessageHandler(handler: handler)
                self.instances[deviceId] = newInstance
                return newInstance
            }
        }
    }
}

