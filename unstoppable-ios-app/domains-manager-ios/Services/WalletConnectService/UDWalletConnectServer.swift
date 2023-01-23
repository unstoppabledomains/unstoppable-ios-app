//
//  UDWalletConnectServer.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.10.2022.
//

import Foundation
import WalletConnectSwift

protocol UDWalletConnectServerResponseDelegate: AnyObject {
    func udWalletConnectServer(_ server: UDWalletConnectServer, willSendResponse response: Response)
}

final class UDWalletConnectServer: Server {
    
    weak var responseDelegate: UDWalletConnectServerResponseDelegate?
    
    override func send(_ response: Response) {
        if let error = response.error,
           error.code == WalletConnectSwift.ResponseError.invalidJSON.rawValue {
            // Ping pong error inside of WC SDK
        } else {
            // Response from WCSigner
            responseDelegate?.udWalletConnectServer(self, willSendResponse: response)
        }
        super.send(response)
    }
    
}
