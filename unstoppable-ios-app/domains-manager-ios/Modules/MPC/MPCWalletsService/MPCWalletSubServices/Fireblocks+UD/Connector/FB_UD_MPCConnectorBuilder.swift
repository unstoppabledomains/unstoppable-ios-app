//
//  MPCConnectorBuilder.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

extension FB_UD_MPC {
    protocol MPCConnectorBuilder {
        func buildBootstrapMPCConnector(deviceId: String,
                                        accessToken: String) throws -> MPCConnector
        func buildWalletMPCConnector(wallet: ConnectedWalletDetails,
                                     authTokenProvider: WalletAuthTokenProvider) throws -> MPCConnector
    }
}
