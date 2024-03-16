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
    
    func stopJoinWallet() { }
    
    func waitForKeyIsReady() async throws {
        await Task.sleep(seconds: 0.5)
    }
    
    func signTransactionWith(txId: String) async throws {
        await Task.sleep(seconds: 0.5)
    }
}

struct DefaultMPCConnectionNetworkService: MPCConnectionNetworkService {
    func sendBootstrapCodeTo(email: String) async throws {
        await Task.sleep(seconds: 0.5)
    }
    
    func submitBootstrapCode(_ code: String) async throws -> MPCBootstrapCodeSubmitResponse {
        await Task.sleep(seconds: 0.5)
        return .init(accessToken: "sd", deviceId: "1")
    }
    
    func authNewDeviceWith(requestId: String, recoveryPhrase: String, accessToken: String) async throws {
        await Task.sleep(seconds: 0.5)
    }
    
    func initTransactionWithNewKeyMaterials(accessToken: String) async throws -> MPCSetupTokenResponse {
        await Task.sleep(seconds: 0.5)
        return .init(transactionId: "1", status: "r")
    }
    
    func waitForTransactionWithNewKeyMaterialsReady(accessToken: String) async throws {
        await Task.sleep(seconds: 0.5)
    }
    
    func confirmTransactionWithNewKeyMaterialsSigned(accessToken: String) async throws -> MPCSuccessAuthResponse {
        await Task.sleep(seconds: 0.5)
        return .init(accessToken: "a", refreshToken: "r", bootstrapToken: "b")
    }
    
    func verifyAccessToken(_ accessToken: String) async throws {
        await Task.sleep(seconds: 0.5)
    }
}
