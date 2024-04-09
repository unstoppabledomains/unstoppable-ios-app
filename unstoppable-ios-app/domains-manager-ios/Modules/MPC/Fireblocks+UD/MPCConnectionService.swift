//
//  MPCNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//


///MPCWalletSetupService
///MPCWalletSetupStep
///
///MPCConnector -> MPCProviderConnector
///MPCConnectorBuilder -> MPCProviderConnectorBuilder
///

import Foundation

func logMPC(_ message: String) {
    print("MPC: - \(message)")
}

extension FB_UD_MPC {
    final class MPCConnectionService {
        
        private let connectorBuilder: MPCConnectorBuilder
        private let networkService: MPCConnectionNetworkService
        
        static let shared = MPCConnectionService(connectorBuilder: DefaultMPCConnectorBuilder())
        
        private init(connectorBuilder: MPCConnectorBuilder,
                     networkService: MPCConnectionNetworkService = DefaultMPCConnectionNetworkService()) {
            self.connectorBuilder = connectorBuilder
            self.networkService = networkService
        }
        
    }
}

// MARK: - Open methods
extension FB_UD_MPC.MPCConnectionService {
    /// Currently it will use admin route to generate code and log intro console.
    func sendBootstrapCodeTo(email: String) async throws {
        try await networkService.sendBootstrapCodeTo(email: email)
    }

    func signForNewDeviceWith(code: String,
                              recoveryPhrase: String) -> AsyncThrowingStream<SetupMPCWalletStep, Error> {
        AsyncThrowingStream { continuation in
            Task {
                continuation.yield(.submittingCode)
                logMPC("Will submit code \(code). recoveryPhrase: \(recoveryPhrase)")
                let submitCodeResponse = try await networkService.submitBootstrapCode(code)
                logMPC("Did submit code \(code)")
                let accessToken = submitCodeResponse.accessToken
                let deviceId = submitCodeResponse.deviceId
                
                continuation.yield(.initialiseFireblocks)
                
                logMPC("Will create fireblocks connector")
                let mpcConnector = try connectorBuilder.buildMPCConnector(deviceId: deviceId, accessToken: accessToken)
                
                mpcConnector.stopJoinWallet()
                logMPC("Did create fireblocks connector")
                logMPC("Will request to join existing wallet")
                do {
                    continuation.yield(.requestingToJoinExistingWallet)
                    let requestId = try await mpcConnector.requestJoinExistingWallet()
                    logMPC("Will auth new device with request id: \(requestId)")
                    // Once we have the key material, now it’s time to get a full access token to the Wallets API. To prove that the key material is valid, you need to create a transaction to sign
                    // Initialize a transaction with the Wallets API
                    continuation.yield(.authorisingNewDevice)
                    try await networkService.authNewDeviceWith(requestId: requestId,
                                                recoveryPhrase: recoveryPhrase,
                                                accessToken: accessToken)
                    logMPC("Did auth new device with request id: \(requestId)")
                    logMPC("Will wait for key is ready")
                    continuation.yield(.waitingForKeysIsReady)
                    try await mpcConnector.waitForKeyIsReady()
                    
                    logMPC("Will init transaction with new key materials")
                    continuation.yield(.initialiseTransaction)
                    let transactionDetails = try await networkService.initTransactionWithNewKeyMaterials(accessToken: accessToken)
                    let txId = transactionDetails.transactionId
                    logMPC("Did init transaction with new key materials with tx id: \(txId)")
                    
                    /// Skipping this part because iOS doesn't have equal functions. To discuss with Wallet team
                    /*
                     const inProg = await sdk.getInProgressSigningTxId();
                     if (inProg && inProg !== tx.transactionId) {
                     this.logger.warn('Encountered in progress tx', { inProg });
                     await sdk.stopInProgressSignTransaction();
                     }
                     */
                    
                    //    We have to wait for Fireblocks to also sign, so poll the Wallets API until the transaction is returned with the PENDING_SIGNATURE status
                    logMPC("Will wait for transaction with new key materials is ready with tx id: \(txId)")
                    continuation.yield(.waitingForTransactionIsReady)
                    try await networkService.waitForTransactionWithNewKeyMaterialsReady(accessToken: accessToken)
                    
                    logMPC("Will sign transaction with fireblocks. txId: \(txId)")
                    continuation.yield(.signingTransaction)
                    try await mpcConnector.signTransactionWith(txId: txId)
                    
                    //    Once it is pending a signature, sign with the Fireblocks NCW SDK and confirm with the Wallets API that you have signed. After confirmation is validated, you’ll be returned an access token, a refresh token and a bootstrap token.
                    logMPC("Will confirm transaction is signed")
                    continuation.yield(.confirmingTransaction)
                    let finalAuthResponse = try await networkService.confirmTransactionWithNewKeyMaterialsSigned(accessToken: accessToken)
                    logMPC("Did confirm transaction is signed")
                    
                    logMPC("Will verify final response \(finalAuthResponse)")
                    continuation.yield(.verifyingAccessToken)
                    try await networkService.verifyAccessToken(finalAuthResponse.accessToken.jwt)
                    logMPC("Did verify final response \(finalAuthResponse) success")
                    
                    let mpcWallet = FB_UD_MPC.WalletDetails(deviceId: deviceId,
                                                            tokens: .init(refreshToken: finalAuthResponse.refreshToken,
                                                                          bootstrapToken: finalAuthResponse.bootstrapToken))
//                    continuation.yield(.finished(mpcWallet))
                    continuation.finish()
                } catch {
                    mpcConnector.stopJoinWallet()
                    let logsURL = mpcConnector.getLogsURLs()
                    continuation.yield(.failed(logsURL))
                    continuation.finish()
                    
//                    continuation.finish(throwing: error)
                }
            }
        }
    }
}


protocol NetworkAuthorisedWithBearerService {
    var authToken: String { get }
}

extension NetworkAuthorisedWithBearerService {
    func buildAuthBearerHeader() -> [String : String] {
        ["Authorization":"Bearer \(authToken)"]
    }
}
