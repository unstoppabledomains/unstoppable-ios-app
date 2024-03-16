//
//  MPCConnectorBuilder.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

protocol MPCConnectorBuilder {
    func buildMPCConnector(deviceId: String,
                           accessToken: String) throws -> MPCConnector
}
