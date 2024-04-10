//
//  MPCNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import Foundation

func logMPC(_ message: String) {
    print("MPC: - \(message)")
}

extension FB_UD_MPC {
    final class MPCConnectionService {
        
        let provider: MPCWalletProvider = .fireblocksUD
        
        private let connectorBuilder: FireblocksConnectorBuilder
        private let networkService: MPCConnectionNetworkService
        private let walletsDataStorage: MPCWalletsDataStorage
        private let udWalletsService: UDWalletsServiceProtocol

        init(connectorBuilder: FireblocksConnectorBuilder = DefaultFireblocksConnectorBuilder(),
             networkService: MPCConnectionNetworkService = DefaultMPCConnectionNetworkService(),
             walletsDataStorage: MPCWalletsDataStorage = MPCWalletsDefaultDataStorage(),
             udWalletsService: UDWalletsServiceProtocol) {
            self.connectorBuilder = connectorBuilder
            self.networkService = networkService
            self.walletsDataStorage = walletsDataStorage
            self.udWalletsService = udWalletsService
        }
    }
}

// MARK: - MPCWalletProviderSubServiceProtocol
extension FB_UD_MPC.MPCConnectionService: MPCWalletProviderSubServiceProtocol {
    /// Currently it will use admin route to generate code and log intro console.
    func sendBootstrapCodeTo(email: String) async throws {
        try await networkService.sendBootstrapCodeTo(email: email)
    }

    func setupMPCWalletWith(code: String,
                              recoveryPhrase: String) -> AsyncThrowingStream<SetupMPCWalletStep, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var mpcConnectorInProgress: FB_UD_MPC.FireblocksConnectorProtocol?
                do {
                    continuation.yield(.submittingCode)
                    logMPC("Will submit code \(code). recoveryPhrase: \(recoveryPhrase)")
                    let submitCodeResponse = try await networkService.submitBootstrapCode(code)
                    logMPC("Did submit code \(code)")
                    let accessToken = submitCodeResponse.accessToken
                    let deviceId = submitCodeResponse.deviceId
                    
                    continuation.yield(.initialiseFireblocks)
                    
                    logMPC("Will create fireblocks connector")
                    let mpcConnector = try connectorBuilder.buildBootstrapMPCConnector(deviceId: deviceId, accessToken: accessToken)
                    mpcConnectorInProgress = mpcConnector
                    mpcConnector.stopJoinWallet()
                    logMPC("Did create fireblocks connector")
                    logMPC("Will request to join existing wallet")
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
                    let authTokens = try await networkService.confirmTransactionWithNewKeyMaterialsSigned(accessToken: accessToken)
                    logMPC("Did confirm transaction is signed")
                    
                    logMPC("Will verify final response \(authTokens)")
                    continuation.yield(.verifyingAccessToken)
                    try await networkService.verifyAccessToken(authTokens.accessToken.jwt)
                    logMPC("Did verify final response \(authTokens) success")
                    
                    let walletDetails = try await getWalletAccountDetailsForWalletWith(deviceId: deviceId,
                                                                                       authTokens: authTokens)
                    logMPC("Did get wallet account details")
                    let mpcWallet = FB_UD_MPC.ConnectedWalletDetails(deviceId: deviceId,
                                                                     tokens: authTokens,
                                                                     accounts: walletDetails.accounts,
                                                                     assets: walletDetails.assets)
                    logMPC("Will create UD Wallet")
                    let udWallet = try prepareAndSaveMPCWallet(mpcWallet)
                    logMPC("Did create UD Wallet")
                    
                    continuation.yield(.finished(udWallet))
                    continuation.finish()
                } catch {
                    mpcConnectorInProgress?.stopJoinWallet()
                    logMPC("Did fail to create mpc wallet with error \(error.localizedDescription)")
                    /// Debug Fireblocks SDK issues
//                    let logsURL = mpcConnector.getLogsURLs()
//                    continuation.yield(.failed(logsURL))
//                    continuation.finish()
                    
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func prepareAndSaveMPCWallet(_ mpcWallet: FB_UD_MPC.ConnectedWalletDetails) throws -> UDWallet {
        do {
            try storeConnectedWalletDetails(mpcWallet)
            let udWallet = try createUDWalletFrom(connectedWallet: mpcWallet)
            try udWalletsService.addMPCWallet(udWallet)
            return udWallet
        } catch {
            try? clearConnectedWalletDetails(mpcWallet)
            throw error
        }
    }
    
    private struct WalletDetails {
        let accounts: [FB_UD_MPC.WalletAccount]
        let assets: [FB_UD_MPC.WalletAccountAsset]
    }
    
    private func getWalletAccountDetailsForWalletWith(deviceId: String,
                                               authTokens: FB_UD_MPC.AuthTokens) async throws -> WalletDetails {
        let networkService = FB_UD_MPC.DefaultMPCConnectionNetworkService()
        let accessToken = authTokens.accessToken.jwt
        
        let accountsResponse = try await networkService.getAccounts(accessToken: accessToken)
        let accounts = accountsResponse.items
        var assets: [FB_UD_MPC.WalletAccountAsset] = []
        for account in accounts {
            let assetsResponse = try await networkService.getAccountAssets(accountId: account.id,
                                                             accessToken: accessToken,
                                                             includeBalances: false)
            assets.append(contentsOf: assetsResponse.items)
        }
        
        
        return WalletDetails(accounts: accounts, assets: assets)
    }
    
    private func storeConnectedWalletDetails(_ walletDetails: FB_UD_MPC.ConnectedWalletDetails) throws {
        let tokens = walletDetails.tokens
        let accountsDetails = walletDetails.createWalletAccountsDetails()
        
        try walletsDataStorage.storeAuthTokens(tokens, for: walletDetails.deviceId)
        try walletsDataStorage.storeAccountsDetails(accountsDetails)
    }
    
    func clearConnectedWalletDetails(_ walletDetails: FB_UD_MPC.ConnectedWalletDetails) throws {
        let deviceId = walletDetails.deviceId
        try walletsDataStorage.clearAuthTokensFor(deviceId: deviceId)
        try walletsDataStorage.clearAccountsDetailsFor(deviceId: deviceId)
    }
    
    private func createUDWalletFrom(connectedWallet: FB_UD_MPC.ConnectedWalletDetails) throws -> UDWallet {
        guard let ethAddress = connectedWallet.getETHWalletAddress() else {
            throw MPCConnectionServiceError.failedToGetEthAddress
        }
        
        let fireblocksMetadataEntity = FB_UD_MPC.UDWalletMetadata(deviceId: connectedWallet.deviceId)
        let fireblocksMetadata = try fireblocksMetadataEntity.jsonDataThrowing()
        let mpcMetadata = MPCWalletMetadata(provider: provider, metadata: fireblocksMetadata)
        let udWallet = UDWallet.createMPC(address: ethAddress,
                                          mpcMetadata: mpcMetadata)
        
        return udWallet
    }
    
    enum MPCConnectionServiceError: String, LocalizedError {
        case tokensExpired
        case failedToGetEthAddress
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}

// MARK: - AuthTokenProvider
extension FB_UD_MPC.MPCConnectionService: FB_UD_MPC.WalletAuthTokenProvider {
    func getAuthTokens(wallet: FB_UD_MPC.ConnectedWalletDetails) async throws -> String {
        let deviceId = wallet.deviceId
        let tokens = try walletsDataStorage.retrieveAuthTokensFor(deviceId: deviceId)
        let accessToken = tokens.accessToken
        if !accessToken.isExpired {
            return accessToken.jwt
        }
        
        let refreshToken = tokens.refreshToken
        guard !refreshToken.isExpired else {
            throw MPCConnectionServiceError.tokensExpired
        }
        
        let refreshedTokens = try await networkService.refreshToken(refreshToken.jwt)
        try walletsDataStorage.storeAuthTokens(refreshedTokens, for: deviceId)
        return refreshedTokens.accessToken.jwt
    }
}
