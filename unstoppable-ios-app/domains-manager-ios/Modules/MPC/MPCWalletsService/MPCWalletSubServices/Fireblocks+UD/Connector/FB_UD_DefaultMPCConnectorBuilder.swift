//
//  FireblocksMPCConnectorBuilder.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

extension FB_UD_MPC {
    struct DefaultMPCConnectorBuilder: MPCConnectorBuilder {
        func buildBootstrapMPCConnector(deviceId: String,
                               accessToken: String) throws -> any MPCConnector {
            let rpcHandler = FireblocksBootstrapRPCMessageHandler(authToken: accessToken)
            
            let connector = try FireblocksConnector(deviceId: deviceId,
                                                    messageHandler: rpcHandler)
            
            return connector
        }
        
        func buildWalletMPCConnector(wallet: ConnectedWalletDetails,
                                     authTokenProvider: WalletAuthTokenProvider) throws -> MPCConnector {
            let deviceId = wallet.deviceId
            let rpcHandler = FireblocksWalletRPCMessageHandler(wallet: wallet,
                                                               authTokenProvider: authTokenProvider)
            
            let connector = try FireblocksConnector(deviceId: deviceId,
                                                    messageHandler: rpcHandler)
            
            return connector
        }
    }
}
