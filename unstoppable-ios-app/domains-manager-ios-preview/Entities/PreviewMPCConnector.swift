//
//  PreviewMPCConnector.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

extension FB_UD_MPC {
    struct DefaultMPCConnectorBuilder: MPCConnectorBuilder {
        func buildMPCConnector(deviceId: String, accessToken: String) throws -> any MPCConnector {
            PreviewMPCConnector()
        }
    }
    
    final class PreviewMPCConnector: MPCConnector {
        func getLogsURLs() -> URL? {
            nil
        }
        
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
        
        func submitBootstrapCode(_ code: String) async throws -> BootstrapCodeSubmitResponse {
            await Task.sleep(seconds: 0.5)
            return .init(accessToken: "sd", deviceId: "1")
        }
        
        func authNewDeviceWith(requestId: String, recoveryPhrase: String, accessToken: String) async throws {
            await Task.sleep(seconds: 0.5)
        }
        
        func initTransactionWithNewKeyMaterials(accessToken: String) async throws -> SetupTokenResponse {
            await Task.sleep(seconds: 0.5)
            return .init(transactionId: "1", status: "r")
        }
        
        func waitForTransactionWithNewKeyMaterialsReady(accessToken: String) async throws {
            await Task.sleep(seconds: 0.5)
        }
        
        func confirmTransactionWithNewKeyMaterialsSigned(accessToken: String) async throws -> SuccessAuthResponse {
            await Task.sleep(seconds: 0.5)
            let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwczovL2FwaS51bnN0b3BwYWJsZWRvbWFpbnMuY29tL2NsYWltcy90b2tlbi1wdXJwb3NlIjoiQUNDRVNTIiwiaHR0cHM6Ly9hcGkudW5zdG9wcGFibGVkb21haW5zLmNvbS9jbGFpbXMvYWNjb3VudCI6IldBTExFVF9VU0VSIiwiaHR0cHM6Ly9hcGkudW5zdG9wcGFibGVkb21haW5zLmNvbS9jbGFpbXMvY29udGV4dCI6Imo2L2UvYjUzbHM2NFNHL25peXRzUTZDek5HdEpPcENiQkJNV3YxNmIzSDh2VmtQOUZmUnUrM3dWM2M5VTBCSlBaZ3JtVGozaGlzNEk2M1M1RE5xNzhtU0ZVbG40ZTZDc1VpU3laenNKSFVVNURYdGVQQjRyZFBDNS9CVXlSMmtsajY0cldIdEVQSmJUcTM5RnJneFErdk5hOTRvT21na0hkRXAraWxJTU4zUHJLS3ExSHdmNzVKdUtJS2dFRnFKZUg5TDY1b1ZtTnNOZ0JGb0hmeW15RnVNcjhzKzdCU2twNXdTd00rZzVBbktydXA4d1MxZStPNWNHM29IblFYZFgwa3NhckxkSlpybEl4NXAvR0xjbVY4RTh3TWl4WkJqcTBuYm4rdDBDSDVyRWhtN25NQmZseGhRWDZPRjVLL1QyVGdWTVVaSmxPQXVLMWI1RDZwdUg4K09seEE5OTU2bWZNejBOQmZyekJ6cFowSmozSDNxcGh1aVNZbjgrT1BHRENwSDh6Qk1iOTJlUHYrWmxSVVlMNHNEYzlidXp6L1paQW9VUGZIclVNdW55cnlzaGFBb0p5aGhEelRWWW10QWg3Y3RnMTRIVFpjRnRiSG5vUkdIUnRrTTlLWVd0Vkd3bHRKMk94akJVUUpzYnl0dnlURFplWHJYM0UyZU1WQ0VMVFZJQk5RPT0iLCJpYXQiOjE3MTIzMDIyMjQsImV4cCI6MTcxMjMxNjYyNCwiYXVkIjoiOTY2MzNhMWMtMmI3MC00N2NhLWEwNmYtMDFiZWY2YjhmMzZiIiwiaXNzIjoiaHR0cHM6Ly9hcGkudW5zdG9wcGFibGVkb21haW5zLmNvbSJ9.A9AFzP-m7KvRdVMPNeYfmmFBSgFeZWBG_WONlmjp6lk"
            let accessToken = try JWToken(jwt)
            let refreshToken = try JWToken(jwt)
            let bootstrapToken = try JWToken(jwt)
            return .init(accessToken: accessToken,
                         refreshToken: refreshToken,
                         bootstrapToken: bootstrapToken)
        }
        
        func verifyAccessToken(_ accessToken: String) async throws {
            await Task.sleep(seconds: 0.5)
        }
    }
}
