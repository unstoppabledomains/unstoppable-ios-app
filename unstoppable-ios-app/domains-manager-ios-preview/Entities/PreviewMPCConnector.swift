//
//  PreviewMPCConnector.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

struct DefaultMPCConnectorBuilder: MPCConnectorBuilder {
    func buildMPCConnector(deviceId: String, accessToken: String) throws -> any MPCConnector {
        PreviewMPCConnector()
    }
}

final class PreviewMPCConnector: MPCConnector {
    func requestJoinExistingWallet() async throws -> String {
        await Task.sleep(seconds: 1)
        return "1"
    }
    
    func stopJoinWallet() {
        
    }
    
    func waitForKeyIsReady() async throws {
        await Task.sleep(seconds: 1)
    }
    
    func signTransactionWith(txId: String) async throws {
        await Task.sleep(seconds: 1)
    }
}
