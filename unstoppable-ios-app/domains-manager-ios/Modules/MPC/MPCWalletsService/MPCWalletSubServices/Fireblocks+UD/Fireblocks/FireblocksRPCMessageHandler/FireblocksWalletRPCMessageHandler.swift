//
//  FireblocksWalletRPCMessageHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

final class FireblocksWalletRPCMessageHandler: FireblocksRPCMessageHandler, FireblocksConnectorMessageHandler {
    let wallet: FB_UD_MPC.ConnectedWalletDetails
    let authTokenProvider: FB_UD_MPC.WalletAuthTokenProvider
    
    init(wallet: FB_UD_MPC.ConnectedWalletDetails,
         authTokenProvider: FB_UD_MPC.WalletAuthTokenProvider) {
        self.wallet = wallet
        self.authTokenProvider = authTokenProvider
    }
    
    func handleOutgoingMessage(payload: String,
                               response: @escaping (String?) -> (),
                               error: @escaping (String?) -> ()) {
        Task {
            do {
                let authToken = try await authTokenProvider.getAuthTokens(wallet: wallet)
                passRPC(payload: payload,
                        authToken: authToken,
                        response: response,
                        error: error)
            } catch let serviceError {
                error(serviceError.localizedDescription)
            }
        }
    }
}
