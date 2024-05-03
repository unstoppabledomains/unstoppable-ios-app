//
//  MPCConnectionNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

extension FB_UD_MPC {
    protocol MPCConnectionNetworkService {
        func sendBootstrapCodeTo(email: String) async throws
        func submitBootstrapCode(_ code: String) async throws -> BootstrapCodeSubmitResponse
        func authNewDeviceWith(requestId: String,
                               recoveryPhrase: String,
                               accessToken: String) async throws
        func initTransactionWithNewKeyMaterials(accessToken: String) async throws -> SetupTokenResponse
        func waitForTransactionWithNewKeyMaterialsReady(accessToken: String) async throws
        func confirmTransactionWithNewKeyMaterialsSigned(accessToken: String) async throws -> AuthTokens
        func verifyAccessToken(_ accessToken: String) async throws
        
        func refreshToken(_ refreshToken: String) async throws -> AuthTokens
        func refreshBootstrapToken(_ bootstrapToken: String) async throws -> RefreshBootstrapTokenResponse
        
        func getAccounts(accessToken: String) async throws -> WalletAccountsResponse
        func getAccountAssets(accountId: String,
                              accessToken: String,
                              includeBalances: Bool) async throws -> WalletAccountAssetsResponse
        
        func getSupportedBlockchainAssets(accessToken: String) async throws -> SupportedBlockchainAssetsResponse 
        
        func startMessageSigning(accessToken: String,
                                 accountId: String,
                                 assetId: String,
                                 message: String,
                                 encoding: SignMessageEncoding) async throws -> OperationDetails
        func startAssetTransfer(accessToken: String,
                                accountId: String,
                                assetId: String,
                                destinationAddress: String,
                                amount: Double) async throws -> OperationDetails
        func waitForOperationReadyAndGetTxId(accessToken: String,
                                             operationId: String) async throws -> OperationReadyResponse
        func waitForOperationSignedAndGetTxSignature(accessToken: String,
                                                     operationId: String) async throws -> String
        func waitForOperationCompleted(accessToken: String,
                                       operationId: String) async throws
        func waitForTxCompletedAndGetHash(accessToken: String,
                                          operationId: String) async throws -> String
        
        func fetchCryptoPortfolioForMPC(wallet: String, accessToken: String) async throws -> [WalletTokenPortfolio]
    }
}
