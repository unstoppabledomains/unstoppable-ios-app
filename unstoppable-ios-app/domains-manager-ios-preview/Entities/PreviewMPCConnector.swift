//
//  PreviewMPCConnector.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

extension FB_UD_MPC {
    struct DefaultFireblocksConnectorBuilder: FireblocksConnectorBuilder {
        func buildBootstrapMPCConnector(deviceId: String, accessToken: String) throws -> any FireblocksConnectorProtocol {
            PreviewMPCConnector()
        }
        
        func buildWalletMPCConnector(wallet: ConnectedWalletDetails, authTokenProvider: any WalletAuthTokenProvider) throws -> any FireblocksConnectorProtocol {
            PreviewMPCConnector()
        }
    }
    
    final class PreviewMPCConnector: FireblocksConnectorProtocol {
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
        var otpProvider: FB_UD_MPC.MPCOTPProvider?
        
        func getAssetTransferEstimations(accessToken: String, accountId: String, assetId: String, destinationAddress: String, amount: String) async throws -> FB_UD_MPC.NetworkFeeResponse {
            .init(priority: "", status: "", networkFee: nil)
        }
        
        func startAssetTransfer(accessToken: String, accountId: String, assetId: String, destinationAddress: String, amount: String) async throws -> FB_UD_MPC.OperationDetails {
            .init(id: "1", status: "", type: "")
        }
        
        func startSendETHTransaction(accessToken: String, accountId: String, assetId: String, destinationAddress: String, data: String, value: String) async throws -> FB_UD_MPC.OperationDetails {
            .init(id: "1", status: "", type: "")
        }
        
        func waitForOperationCompleted(accessToken: String, operationId: String) async throws {
            
        }
        
        func waitForTxCompletedAndGetHash(accessToken: String, operationId: String) async throws -> String {
            ""
        }
        
        func fetchCryptoPortfolioForMPC(wallet: String, accessToken: String) async throws -> [WalletTokenPortfolio] {
            MockEntitiesFabric.Wallet.mockEntities()[0].balance
        }
        
        func refreshBootstrapToken(_ bootstrapToken: String) async throws -> FB_UD_MPC.RefreshBootstrapTokenResponse {
            await Task.sleep(seconds: 0.5)
            return .init(accessToken: "", deviceId: "")
        }
        
        func startMessageSigning(accessToken: String, accountId: String, assetId: String, message: String, signingType: FB_UD_MPC.MessageSigningType) async throws -> FB_UD_MPC.OperationDetails {
            await Task.sleep(seconds: 0.5)
            return .init(id: "", status: "", type: "")
        }
        
        func waitForOperationReadyAndGetTxId(accessToken: String, operationId: String) async throws -> FB_UD_MPC.OperationReadyResponse {
            await Task.sleep(seconds: 0.5)
            return .txReady(txId: "")
        }
        
        func waitForOperationSignedAndGetTxSignature(accessToken: String, operationId: String) async throws -> String {
            await Task.sleep(seconds: 0.5)
            return ""
        }
        
        func sendBootstrapCodeTo(email: String) async throws {
            await Task.sleep(seconds: 0.5)
        }
        
        func submitBootstrapCode(_ code: String) async throws -> BootstrapCodeSubmitResponse {
            await Task.sleep(seconds: 0.5)
//            throw MPCWalletError.incorrectCode
            return .init(accessToken: "sd", deviceId: "1")
        }
        
        func authNewDeviceWith(requestId: String, recoveryPhrase: String, accessToken: String) async throws {
            await Task.sleep(seconds: 0.5)
//            throw MPCWalletError.incorrectPassword
        }
        
        func initTransactionWithNewKeyMaterials(accessToken: String) async throws -> SetupTokenResponse {
            await Task.sleep(seconds: 0.5)
            return .init(transactionId: "1", status: "r")
        }
        
        func waitForTransactionWithNewKeyMaterialsReady(accessToken: String) async throws {
            await Task.sleep(seconds: 0.5)
        }
        
        func confirmTransactionWithNewKeyMaterialsSigned(accessToken: String) async throws -> AuthTokens {
            await Task.sleep(seconds: 0.5)
            return try createMockSuccessAuthResponse()
        }
        
        func verifyAccessToken(_ accessToken: String) async throws {
            await Task.sleep(seconds: 0.5)
        }
        
        func refreshToken(_ refreshToken: String) async throws -> AuthTokens {
            await Task.sleep(seconds: 0.5)
            return try createMockSuccessAuthResponse()
        }
        
        func getAccounts(accessToken: String) async throws -> WalletAccountsResponse {
            await Task.sleep(seconds: 0.5)
            return .init(items: [], next: nil)
        }
        
        func getAccountAssets(accountId: String,
                              accessToken: String,
                              includeBalances: Bool) async throws -> WalletAccountAssetsResponse {
            await Task.sleep(seconds: 0.5)
            return .init(items: [], next: nil)
        }
        
        func getSupportedBlockchainAssets(accessToken: String) async throws -> SupportedBlockchainAssetsResponse {
            await Task.sleep(seconds: 0.5)
            return .init(items: [])
        }
        
        func requestRecovery(_ accessToken: String, password: String) async throws {
            await Task.sleep(seconds: 0.5)
        }
        
        func resetPassword(accessToken: String,
                           recoveryToken: String,
                           newRecoveryPhrase: String,
                           requestId: String) async throws {
            await Task.sleep(seconds: 0.5)
        }

        func get2FAStatus(accessToken: String) async throws -> Bool {
            await Task.sleep(seconds: 0.5)
            return false
        }
        
        func enable2FA(accessToken: String) async throws -> String {
            await Task.sleep(seconds: 0.5)
            return ""
        }
        
        func verify2FAToken(accessToken: String, token: String) async throws {
            await Task.sleep(seconds: 0.5)
        }
        
        func disable2FA(accessToken: String, token: String) async throws {
            await Task.sleep(seconds: 0.5)
        }   
    }
    
    struct MPCWalletsDefaultDataStorage: MPCWalletsDataStorage {
        func storeAuthTokens(_ tokens: AuthTokens, for deviceId: String) throws { }
        func clearAuthTokensFor(deviceId: String) throws { }
        func retrieveAuthTokensFor(deviceId: String) throws -> AuthTokens {
            try createMockSuccessAuthResponse()
        }
        
        func storeAccountsDetails(_ accountsDetails: ConnectedWalletAccountsDetails) throws { }
        func clearAccountsDetailsFor(deviceId: String) throws { }
        func retrieveAccountsDetailsFor(deviceId: String) throws -> ConnectedWalletAccountsDetails {
            .init(email: "qq@qq.qq",
                  deviceId: deviceId,
                  firstAccount: .init(account: .init(type: "", id: ""),
                                      assets: []),
                  accounts: [])
        }
    }
    
  
}
private func createMockJWToken() throws -> JWToken {
    let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwczovL2FwaS51bnN0b3BwYWJsZWRvbWFpbnMuY29tL2NsYWltcy90b2tlbi1wdXJwb3NlIjoiQUNDRVNTIiwiaHR0cHM6Ly9hcGkudW5zdG9wcGFibGVkb21haW5zLmNvbS9jbGFpbXMvYWNjb3VudCI6IldBTExFVF9VU0VSIiwiaHR0cHM6Ly9hcGkudW5zdG9wcGFibGVkb21haW5zLmNvbS9jbGFpbXMvY29udGV4dCI6Imo2L2UvYjUzbHM2NFNHL25peXRzUTZDek5HdEpPcENiQkJNV3YxNmIzSDh2VmtQOUZmUnUrM3dWM2M5VTBCSlBaZ3JtVGozaGlzNEk2M1M1RE5xNzhtU0ZVbG40ZTZDc1VpU3laenNKSFVVNURYdGVQQjRyZFBDNS9CVXlSMmtsajY0cldIdEVQSmJUcTM5RnJneFErdk5hOTRvT21na0hkRXAraWxJTU4zUHJLS3ExSHdmNzVKdUtJS2dFRnFKZUg5TDY1b1ZtTnNOZ0JGb0hmeW15RnVNcjhzKzdCU2twNXdTd00rZzVBbktydXA4d1MxZStPNWNHM29IblFYZFgwa3NhckxkSlpybEl4NXAvR0xjbVY4RTh3TWl4WkJqcTBuYm4rdDBDSDVyRWhtN25NQmZseGhRWDZPRjVLL1QyVGdWTVVaSmxPQXVLMWI1RDZwdUg4K09seEE5OTU2bWZNejBOQmZyekJ6cFowSmozSDNxcGh1aVNZbjgrT1BHRENwSDh6Qk1iOTJlUHYrWmxSVVlMNHNEYzlidXp6L1paQW9VUGZIclVNdW55cnlzaGFBb0p5aGhEelRWWW10QWg3Y3RnMTRIVFpjRnRiSG5vUkdIUnRrTTlLWVd0Vkd3bHRKMk94akJVUUpzYnl0dnlURFplWHJYM0UyZU1WQ0VMVFZJQk5RPT0iLCJpYXQiOjE3MTIzMDIyMjQsImV4cCI6MTcxMjMxNjYyNCwiYXVkIjoiOTY2MzNhMWMtMmI3MC00N2NhLWEwNmYtMDFiZWY2YjhmMzZiIiwiaXNzIjoiaHR0cHM6Ly9hcGkudW5zdG9wcGFibGVkb21haW5zLmNvbSJ9.A9AFzP-m7KvRdVMPNeYfmmFBSgFeZWBG_WONlmjp6lk"
    return try JWToken(jwt)
}

private func createMockSuccessAuthResponse() throws -> FB_UD_MPC.AuthTokens {
    let accessToken = try createMockJWToken()
    let refreshToken = try createMockJWToken()
    let bootstrapToken = try createMockJWToken()
    return .init(accessToken: accessToken,
                 refreshToken: refreshToken,
                 bootstrapToken: bootstrapToken)
}
