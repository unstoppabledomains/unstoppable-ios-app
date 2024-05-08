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

struct MPCMessage {
    enum MPCMessageType: String {
        case utf8, hex
    }
    let incomingString: String
    let outcomingString: String
    let type: MPCMessageType
}

extension FB_UD_MPC {
    final class MPCConnectionService {
        
        let provider: MPCWalletProvider = .fireblocksUD
        
        private let connectorBuilder: FireblocksConnectorBuilder
        private let networkService: MPCConnectionNetworkService
        private let walletsDataStorage: MPCWalletsDataStorage
        private let udWalletsService: UDWalletsServiceProtocol
        private let actionsQueuer = ActionsQueuer()

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
                    
                    continuation.yield(.getWalletAccountDetails)
                    let walletDetails = try await getWalletAccountDetailsForWalletWith(deviceId: deviceId,
                                                                                       accessToken: authTokens.accessToken.jwt)
                    logMPC("Did get wallet account details")
                    let mpcWallet = FB_UD_MPC.ConnectedWalletDetails(deviceId: deviceId,
                                                                     tokens: authTokens,
                                                                     firstAccount: walletDetails.firstAccount,
                                                                     accounts: walletDetails.accounts)
                    continuation.yield(.storeWallet)
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
    
    func signMessage(_ messageString: String,
                     chain: BlockchainType,
                     by walletMetadata: MPCWalletMetadata) async throws -> String {
        let connectedWalletDetails = try getConnectedWalletDetailsFor(walletMetadata: walletMetadata)
        let mpcConnector = try connectorBuilder.buildWalletMPCConnector(wallet: connectedWalletDetails,
                                                                        authTokenProvider: self)
        let deviceId = connectedWalletDetails.deviceId
        await waitForActionReadyToStart(deviceId: deviceId)
        defer { Task { await actionsQueuer.removeActive(deviceId: deviceId) } }
        let start = Date()
        let account = connectedWalletDetails.firstAccount
        let asset = try account.getAssetToSignWith(chain: chain)
        let token = try await getAuthTokens(wallet: connectedWalletDetails)
        let mpcMessage = messageString.convertToMPCMessage
        let encoding = convertMPCMessageTypeToFBUDEncoding(mpcMessage.type)
        let requestOperation = try await networkService.startMessageSigning(accessToken: token,
                                                                            accountId: account.id,
                                                                            assetId: asset.id,
                                                                            message: mpcMessage.outcomingString,
                                                                            encoding: encoding)
        let operationId = requestOperation.id
        logMPC("It took \(Date().timeIntervalSince(start)) to get operationId")
        let operationStatus = try await networkService.waitForOperationReadyAndGetTxId(accessToken: token,
                                                                                       operationId: operationId)
        switch operationStatus {
        case .txReady(let txId):
            logMPC("It took \(Date().timeIntervalSince(start)) to get tx id")
            try await mpcConnector.signTransactionWith(txId: txId)
            logMPC("It took \(Date().timeIntervalSince(start)) to sign by mpc connector")
            let signature = try await networkService.waitForOperationSignedAndGetTxSignature(accessToken: token,
                                                                                             operationId: operationId)
            logMPC("It took \(Date().timeIntervalSince(start)) to sign message")
            return signature
        case .signed(let signature):
            logMPC("It took \(Date().timeIntervalSince(start)) to sign message")
            return signature
        }
    }
    
    func canTransferAssets(symbol: String,
                           chain: String,
                           by walletMetadata: MPCWalletMetadata) -> Bool {
        do {
            let connectedWalletDetails = try getConnectedWalletDetailsFor(walletMetadata: walletMetadata)
            let account = connectedWalletDetails.firstAccount
            return account.canSendCryptoTo(symbol: symbol,
                                           chain: chain)
        } catch {
            return false
        }
    }
    
    func transferAssets(_ amount: Double,
                        symbol: String,
                        chain: String,
                        destinationAddress: String,
                        by walletMetadata: MPCWalletMetadata) async throws -> String {
        let connectedWalletDetails = try getConnectedWalletDetailsFor(walletMetadata: walletMetadata)
        let mpcConnector = try connectorBuilder.buildWalletMPCConnector(wallet: connectedWalletDetails,
                                                                        authTokenProvider: self)
        let deviceId = connectedWalletDetails.deviceId
        await waitForActionReadyToStart(deviceId: deviceId)
        defer { Task { await actionsQueuer.removeActive(deviceId: deviceId) } }
        let start = Date()
        let account = connectedWalletDetails.firstAccount
        let asset = try account.getAssetWith(symbol: symbol, chain: chain)
        let token = try await getAuthTokens(wallet: connectedWalletDetails)
        let requestOperation = try await networkService.startAssetTransfer(accessToken: token,
                                                                           accountId: account.id,
                                                                           assetId: asset.id,
                                                                           destinationAddress: destinationAddress,
                                                                           amount: amount)
        let operationId = requestOperation.id
        logMPC("It took \(Date().timeIntervalSince(start)) to get operationId")
        let operationStatus = try await networkService.waitForOperationReadyAndGetTxId(accessToken: token,
                                                                                       operationId: operationId)
        switch operationStatus {
        case .txReady(let txId):
            logMPC("It took \(Date().timeIntervalSince(start)) to get tx id")
            try await mpcConnector.signTransactionWith(txId: txId)
            logMPC("It took \(Date().timeIntervalSince(start)) to sign by mpc connector")
            let txHash = try await networkService.waitForTxCompletedAndGetHash(accessToken: token,
                                                                               operationId: operationId)
            logMPC("It took \(Date().timeIntervalSince(start)) to send crypto")
            return txHash
        case .signed(let signature):
            logMPC("It took \(Date().timeIntervalSince(start)) to send crypto")
            throw MPCConnectionServiceError.incorrectOperationState
        }
    }
    
    func getBalancesFor(wallet: String, walletMetadata: MPCWalletMetadata) async throws -> [WalletTokenPortfolio] {
        let connectedWalletDetails = try await refreshWalletAccountDetailsForWalletWith(walletMetadata: walletMetadata)
        let token = try await getAuthTokens(wallet: connectedWalletDetails)
        let account = connectedWalletDetails.firstAccount
        let assets = account.assets.compactMap({ $0 })
        let addresses = Set(assets.map { $0.address })
        
        var balances = [WalletTokenPortfolio]()
        try await withThrowingTaskGroup(of: [WalletTokenPortfolio].self) { group in
            for address in addresses {
                group.addTask {
                    (try? await self.networkService.fetchCryptoPortfolioForMPC(wallet: address, accessToken: token)) ?? []
                }
            }
            
            for try await balance in group {
                balances.append(contentsOf: balance)
            }
        }
        
        return balances
    }
    
    func getTokens(for walletMetadata: MPCWalletMetadata) throws -> [BalanceTokenUIDescription] {
        let connectedWalletDetails = try getConnectedWalletDetailsFor(walletMetadata: walletMetadata)
        let account = connectedWalletDetails.firstAccount
        
        return account.createTokens()
    }
    
    private func convertMPCMessageTypeToFBUDEncoding(_ type: MPCMessage.MPCMessageType) -> FB_UD_MPC.SignMessageEncoding {
        switch type {
        case .hex:
            return .hex
        case .utf8:
            return .utf8
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
        let firstAccount: FB_UD_MPC.WalletAccountWithAssets
        let accounts: [FB_UD_MPC.WalletAccountWithAssets]
    }
    
    private func refreshWalletAccountDetailsForWalletWith(walletMetadata: MPCWalletMetadata) async throws -> FB_UD_MPC.ConnectedWalletDetails {
        let connectedWalletDetails = try getConnectedWalletDetailsFor(walletMetadata: walletMetadata)
        let deviceId = connectedWalletDetails.deviceId
        let token = try await getAuthTokens(wallet: connectedWalletDetails)
        let walletAccountDetails = try await getWalletAccountDetailsForWalletWith(deviceId: deviceId,
                                                                                  accessToken: token)

        let authTokens = try walletsDataStorage.retrieveAuthTokensFor(deviceId: deviceId)
        let mpcWallet = FB_UD_MPC.ConnectedWalletDetails(deviceId: deviceId,
                                                         tokens: authTokens,
                                                         firstAccount: walletAccountDetails.firstAccount,
                                                         accounts: walletAccountDetails.accounts)
        try walletsDataStorage.storeAccountsDetails(mpcWallet.createWalletAccountsDetails())

        return mpcWallet
    }
    
    private func getWalletAccountDetailsForWalletWith(deviceId: String,
                                                      accessToken: String) async throws -> WalletDetails {
        let networkService = FB_UD_MPC.DefaultMPCConnectionNetworkService()
        
        let accountsResponse = try await networkService.getAccounts(accessToken: accessToken)
        let accounts = accountsResponse.items
        var accountsWithAssets: [FB_UD_MPC.WalletAccountWithAssets] = []
        for account in accounts {
            let assetsResponse = try await networkService.getAccountAssets(accountId: account.id,
                                                                           accessToken: accessToken,
                                                                           includeBalances: false)
            let accountWithAssets = FB_UD_MPC.WalletAccountWithAssets(account: account,
                                                                      assets: assetsResponse.items)
            accountsWithAssets.append(accountWithAssets)
        }
        guard let firstAccount = accountsWithAssets.first else { throw MPCConnectionServiceError.noAccountsForWallet }
        
        return WalletDetails(firstAccount: firstAccount,
                             accounts: accountsWithAssets)
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
    
    private func getConnectedWalletDetailsFor(deviceId: String) throws -> FB_UD_MPC.ConnectedWalletDetails {
        let tokens = try walletsDataStorage.retrieveAuthTokensFor(deviceId: deviceId)
        let accountDetails = try walletsDataStorage.retrieveAccountsDetailsFor(deviceId: deviceId)
        return .init(accountDetails: accountDetails, tokens: tokens)
    }
    
    private func getConnectedWalletDetailsFor(walletMetadata: MPCWalletMetadata) throws -> FB_UD_MPC.ConnectedWalletDetails {
        let deviceId = try getDeviceIdFrom(walletMetadata: walletMetadata)
        let connectedWalletDetails = try getConnectedWalletDetailsFor(deviceId: deviceId)
        return connectedWalletDetails
    }
    
    private func getDeviceIdFrom(walletMetadata: MPCWalletMetadata) throws -> String {
        guard let metadata = walletMetadata.metadata else { throw MPCConnectionServiceError.invalidWalletMetadata }
        let walletMetadata = try FB_UD_MPC.UDWalletMetadata.objectFromDataThrowing(metadata)
        let deviceId = walletMetadata.deviceId
        return deviceId
    }
    
    private func waitForActionReadyToStart(deviceId: String) async {
        let isReady = await actionsQueuer.setActiveIfReady(deviceId: deviceId)
        if !isReady {
            await Task.sleep(seconds: 1)
            await waitForActionReadyToStart(deviceId: deviceId)
        }
    }
    
    enum MPCConnectionServiceError: String, LocalizedError {
        case tokensExpired
        case failedToGetEthAddress
        case noAccountsForWallet
        case invalidWalletMetadata
        case incorrectOperationState
        
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
        if !refreshToken.isExpired {
            return try await refreshAndStoreToken(refreshToken: refreshToken, deviceId: deviceId)
        }
        
        let bootstrapToken = tokens.bootstrapToken
        if !bootstrapToken.isExpired {
            return try await refreshAndStoreBootstrapToken(bootstrapToken: bootstrapToken,
                                                           currentDeviceId: deviceId)
        }
        
        // All tokens has expired. Need to go through the bootstrap process from the beginning.
        throw MPCConnectionServiceError.tokensExpired
    }
    
    func refreshAndStoreToken(refreshToken: JWToken,
                              deviceId: String) async throws -> String {
        let refreshedTokens = try await networkService.refreshToken(refreshToken.jwt)
        try walletsDataStorage.storeAuthTokens(refreshedTokens, for: deviceId)
        return refreshedTokens.accessToken.jwt
    }
    
    func refreshAndStoreBootstrapToken(bootstrapToken: JWToken,
                                       currentDeviceId: String) async throws -> String {
        let refreshBootstrapTokenResponse = try await networkService.refreshBootstrapToken(bootstrapToken.jwt)
        
        let accessToken = refreshBootstrapTokenResponse.accessToken
        let deviceId = refreshBootstrapTokenResponse.deviceId
        let mpcConnector = try connectorBuilder.buildBootstrapMPCConnector(deviceId: deviceId, accessToken: accessToken)
        mpcConnector.stopJoinWallet()
        
        try await mpcConnector.waitForKeyIsReady()
        let transactionDetails = try await networkService.initTransactionWithNewKeyMaterials(accessToken: accessToken)
        let txId = transactionDetails.transactionId
        try await networkService.waitForTransactionWithNewKeyMaterialsReady(accessToken: accessToken)
        try await mpcConnector.signTransactionWith(txId: txId)
        let authTokens = try await networkService.confirmTransactionWithNewKeyMaterialsSigned(accessToken: accessToken)
        
        try walletsDataStorage.clearAuthTokensFor(deviceId: currentDeviceId)
        try walletsDataStorage.storeAuthTokens(authTokens, for: deviceId)
        return authTokens.accessToken.jwt
    }
}

// MARK: - Queuing
extension FB_UD_MPC.MPCConnectionService {
    actor ActionsQueuer {
        private var ongoingDeviceIds: Set<String> = []
        
        func isActive(deviceId: String) -> Bool {
            ongoingDeviceIds.contains(deviceId)
        }
        
        func setActiveIfReady(deviceId: String) -> Bool {
            if !isActive(deviceId: deviceId) {
                ongoingDeviceIds.insert(deviceId)
                return true
            } else {
                return false
            }
        }
        
        func removeActive(deviceId: String) {
            ongoingDeviceIds.remove(deviceId)
        }
    }
}
