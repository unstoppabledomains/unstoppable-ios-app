//
//  MPCNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import Foundation

func logMPC(_ message: String) {
    #if DEBUG
    Debugger.printInfo(topic: .mpc, message)
    #endif
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
        private let uiHandler: MPCWalletsUIHandler
        private let actionsQueuer = ActionsQueuer()

        init(connectorBuilder: FireblocksConnectorBuilder = DefaultFireblocksConnectorBuilder(),
             networkService: MPCConnectionNetworkService = DefaultMPCConnectionNetworkService(),
             walletsDataStorage: MPCWalletsDataStorage = MPCWalletsDefaultDataStorage(),
             udWalletsService: UDWalletsServiceProtocol,
             uiHandler: MPCWalletsUIHandler) {
            self.connectorBuilder = connectorBuilder
            self.networkService = networkService
            self.walletsDataStorage = walletsDataStorage
            self.udWalletsService = udWalletsService
            self.uiHandler = uiHandler
            udWalletsService.addListener(self)
        }
    }
}

// MARK: - MPCWalletProviderSubServiceProtocol
extension FB_UD_MPC.MPCConnectionService: MPCWalletProviderSubServiceProtocol {
    func sendBootstrapCodeTo(email: String) async throws {
        try await networkService.sendBootstrapCodeTo(email: email)
    }

    func setupMPCWalletWith(code: String,
                            credentials: MPCActivateCredentials) -> AsyncThrowingStream<SetupMPCWalletStep, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var mpcConnectorInProgress: FB_UD_MPC.FireblocksConnectorProtocol?
                let email = credentials.email
                let recoveryPhrase = credentials.password
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
                    let mpcWallet = FB_UD_MPC.ConnectedWalletDetails(email: email,
                                                                     deviceId: deviceId,
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
                    #if DEBUG
                    /// Debug Fireblocks SDK issues
                    if let logsURL = mpcConnectorInProgress?.getLogsURLs(),
                       let view = await appContext.coreAppCoordinator.topVC {
                       await view.shareItems([logsURL], completion: nil)
                    }
                    #endif
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func signPersonalMessage(_ messageString: String,
                             chain: BlockchainType,
                             by walletMetadata: MPCWalletMetadata) async throws -> String {
        let mpcMessage = messageString.convertToMPCMessage
        let encoding = convertMPCMessageTypeToFBUDEncoding(mpcMessage.type)
        
        return try await signMessage(mpcMessage.outcomingString,
                                     signingType: .personalSign(encoding),
                                     chain: chain,
                                     by: walletMetadata)
    }
    
    func signTypedDataMessage(_ message: String,
                              chain: BlockchainType,
                              by walletMetadata: MPCWalletMetadata) async throws -> String {
        try await signMessage(message,
                              signingType: .typedData,
                              chain: chain,
                              by: walletMetadata)
    }
    
    private func signMessage(_ message: String,
                             signingType: FB_UD_MPC.MessageSigningType,
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
        
        return try await performAuthErrorCatchingBlock(connectedWalletDetails: connectedWalletDetails) { token in
            let requestOperation = try await networkService.startMessageSigning(accessToken: token,
                                                                                accountId: account.id,
                                                                                assetId: asset.id,
                                                                                message: message,
                                                                                signingType: signingType)
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
        let account = connectedWalletDetails.firstAccount
        let asset = try account.getAssetWith(symbol: symbol, chain: chain)
        let amount = try trimAmount(amount, forAsset: asset)
        
        return try await performAuthErrorCatchingBlock(connectedWalletDetails: connectedWalletDetails) { token in
            let requestOperation = try await networkService.startAssetTransfer(accessToken: token,
                                                                               accountId: account.id,
                                                                               assetId: asset.id,
                                                                               destinationAddress: destinationAddress,
                                                                               amount: amount)
            let txHash = try await signOperationAndGetHash(requestOperation,
                                                           token: token,
                                                           mpcConnector: mpcConnector)
            return txHash
        }
    }
    
    func sendETHTransaction(data: String,
                            value: String,
                            chain: BlockchainType,
                            destinationAddress: String,
                            by walletMetadata: MPCWalletMetadata) async throws -> String {
        let connectedWalletDetails = try getConnectedWalletDetailsFor(walletMetadata: walletMetadata)
        let mpcConnector = try connectorBuilder.buildWalletMPCConnector(wallet: connectedWalletDetails,
                                                                        authTokenProvider: self)
        let deviceId = connectedWalletDetails.deviceId
        await waitForActionReadyToStart(deviceId: deviceId)
        defer { Task { await actionsQueuer.removeActive(deviceId: deviceId) } }
        let account = connectedWalletDetails.firstAccount
        let asset = try account.getAssetToSignWith(chain: chain)

        return try await performAuthErrorCatchingBlock(connectedWalletDetails: connectedWalletDetails) { token in
            let requestOperation = try await networkService.startSendETHTransaction(accessToken: token,
                                                                                    accountId: account.id,
                                                                                    assetId: asset.id,
                                                                                    destinationAddress: destinationAddress,
                                                                                    data: data,
                                                                                    value: value)
            let txHash = try await signOperationAndGetHash(requestOperation,
                                                           token: token,
                                                           mpcConnector: mpcConnector)
            return txHash
        }
    }
    
    private func signOperationAndGetHash(_ operation: FB_UD_MPC.OperationDetails,
                                         token: String,
                                         mpcConnector: FB_UD_MPC.FireblocksConnectorProtocol) async throws -> String {
        let start = Date()
        let operationId = operation.id
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
            logMPC("It took \(Date().timeIntervalSince(start)) to finish tx")
            return txHash
        case .signed:
            logMPC("It took \(Date().timeIntervalSince(start)) to finish tx")
            throw MPCConnectionServiceError.incorrectOperationState
        }
    }
    
    func fetchGasFeeFor(_ amount: Double,
                        symbol: String,
                        chain: String,
                        destinationAddress: String,
                        by walletMetadata: MPCWalletMetadata) async throws -> Double {
        let connectedWalletDetails = try getConnectedWalletDetailsFor(walletMetadata: walletMetadata)
        let account = connectedWalletDetails.firstAccount
        let asset = try account.getAssetWith(symbol: symbol, chain: chain)
        let amount = try trimAmount(amount, forAsset: asset)

        return try await performAuthErrorCatchingBlock(connectedWalletDetails: connectedWalletDetails) { token in
            let estimations = try await networkService.getAssetTransferEstimations(accessToken: token,
                                                                                   accountId: account.id,
                                                                                   assetId: asset.id,
                                                                                   destinationAddress: destinationAddress,
                                                                                   amount: amount)
            guard let networkFee = estimations.networkFee else {
                throw MPCConnectionServiceError.missingNetworkFee
            }
            
            guard let amount = Double(networkFee.amount) else {
                throw MPCConnectionServiceError.invalidNetworkFeeAmountFormat
            }
            
            return amount
        }
    }
    
    private func trimAmount(_ amount: Double, forAsset asset: FB_UD_MPC.WalletAccountAsset) throws -> String {
        let trimLimit = asset.balance?.decimals ?? 9
        return amount.formatted(toMaxNumberAfterComa: trimLimit)
    }
    
    func getBalancesFor(walletMetadata: MPCWalletMetadata) async throws -> [WalletTokenPortfolio] {
        let connectedWalletDetails = try await refreshWalletAccountDetailsForWalletWith(walletMetadata: walletMetadata)
        return try await performAuthErrorCatchingBlock(connectedWalletDetails: connectedWalletDetails) { token in
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
    }
    
    func getTokens(for walletMetadata: MPCWalletMetadata) throws -> [BalanceTokenUIDescription] {
        let connectedWalletDetails = try getConnectedWalletDetailsFor(walletMetadata: walletMetadata)
        let account = connectedWalletDetails.firstAccount
        
        return account.createTokens()
    }
    
    func requestRecovery(for walletMetadata: MPCWalletMetadata,
                         password: String) async throws -> String {
        let connectedWalletDetails = try getConnectedWalletDetailsFor(walletMetadata: walletMetadata)
        
        return try await performAuthErrorCatchingBlock(connectedWalletDetails: connectedWalletDetails) { token in
            try await networkService.requestRecovery(token, password: password)
            return connectedWalletDetails.email
        }    
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
        let email = connectedWalletDetails.email
        let deviceId = connectedWalletDetails.deviceId
        return try await performAuthErrorCatchingBlock(connectedWalletDetails: connectedWalletDetails) { token in
            let walletAccountDetails = try await getWalletAccountDetailsForWalletWith(deviceId: deviceId,
                                                                                      accessToken: token)
            
            let authTokens = try walletsDataStorage.retrieveAuthTokensFor(deviceId: deviceId)
            let mpcWallet = FB_UD_MPC.ConnectedWalletDetails(email: email,
                                                             deviceId: deviceId,
                                                             tokens: authTokens,
                                                             firstAccount: walletAccountDetails.firstAccount,
                                                             accounts: walletAccountDetails.accounts)
            try walletsDataStorage.storeAccountsDetails(mpcWallet.createWalletAccountsDetails())
            
            return mpcWallet
        }
    }
    
    private func getWalletAccountDetailsForWalletWith(deviceId: String,
                                                      accessToken: String) async throws -> WalletDetails {
        let accountsResponse = try await networkService.getAccounts(accessToken: accessToken)
        let accounts = accountsResponse.items
        var accountsWithAssets: [FB_UD_MPC.WalletAccountWithAssets] = []
        for account in accounts {
            let assetsResponse = try await networkService.getAccountAssets(accountId: account.id,
                                                                           accessToken: accessToken,
                                                                           includeBalances: true)
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
        try clearWalletDetails(deviceId: deviceId)
    }
    
    func clearWalletDetails(deviceId: String) throws {
        try walletsDataStorage.clearAuthTokensFor(deviceId: deviceId)
        try walletsDataStorage.clearAccountsDetailsFor(deviceId: deviceId)
    }
    
    private func createUDWalletFrom(connectedWallet: FB_UD_MPC.ConnectedWalletDetails) throws -> UDWallet {
        guard let ethAddress = connectedWallet.getETHWalletAddress() else {
            throw MPCConnectionServiceError.failedToGetEthAddress
        }
        
        let fireblocksMetadataEntity = FB_UD_MPC.UDWalletMetadata(email: connectedWallet.email,
                                                                  deviceId: connectedWallet.deviceId)
        let fireblocksMetadata = try fireblocksMetadataEntity.jsonDataThrowing()
        let mpcMetadata = MPCWalletMetadata(provider: provider, metadata: fireblocksMetadata)
        let udWallet = try udWalletsService.createMPCWallet(ethAddress: ethAddress,
                                                            mpcMetadata: mpcMetadata)
        
        return udWallet
    }
    
    private func getConnectedWalletDetailsFor(deviceId: String) throws -> FB_UD_MPC.ConnectedWalletDetails {
        let tokens = try walletsDataStorage.retrieveAuthTokensFor(deviceId: deviceId)
        let accountDetails = try walletsDataStorage.retrieveAccountsDetailsFor(deviceId: deviceId)
        return FB_UD_MPC.ConnectedWalletDetails(accountDetails: accountDetails, tokens: tokens)
    }
    
    private func getConnectedWalletDetailsFor(walletMetadata: MPCWalletMetadata) throws -> FB_UD_MPC.ConnectedWalletDetails {
        let metadata = try getFBUDWalletMetadataFrom(walletMetadata: walletMetadata)
        let connectedWalletDetails = try getConnectedWalletDetailsFor(deviceId: metadata.deviceId)
        return connectedWalletDetails
    }
    
    private func getFBUDWalletMetadataFrom(walletMetadata: MPCWalletMetadata) throws -> FB_UD_MPC.UDWalletMetadata {
        guard let metadata = walletMetadata.metadata else { throw MPCConnectionServiceError.invalidWalletMetadata }
        let walletMetadata = try FB_UD_MPC.UDWalletMetadata.objectFromDataThrowing(metadata)
        return walletMetadata
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
        case missingNetworkFee
        case invalidNetworkFeeAmountFormat
        case failedToTrimAmount
        case failedToFindUDWallet
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}

// MARK: - AuthTokenProvider
extension FB_UD_MPC.MPCConnectionService: FB_UD_MPC.WalletAuthTokenProvider {
    func getAuthTokens(wallet: FB_UD_MPC.ConnectedWalletDetails) async throws -> String {
        try await getFreshAccessTokenFor(wallet: wallet, forceRefresh: false)
    }
    
    private func getFreshAccessTokenFor(wallet: FB_UD_MPC.ConnectedWalletDetails,
                                     forceRefresh: Bool = false) async throws -> String {
        let deviceId = wallet.deviceId
        if let getTokenTask = await actionsQueuer.getTokenTask(deviceId: deviceId) {
            return try await getTokenTask.value
        }
        
        let getTokenTask = Task<String, Error> {
            let deviceId = wallet.deviceId
            let tokens = try walletsDataStorage.retrieveAuthTokensFor(deviceId: deviceId)
            let accessToken = tokens.accessToken
            if !accessToken.isExpired,
               !forceRefresh {
                return accessToken.jwt
            }
            
            let refreshToken = tokens.refreshToken
            if !refreshToken.isExpired {
                let token = try await refreshAndStoreToken(refreshToken: refreshToken, deviceId: deviceId)
                return token
            }
            
            let bootstrapToken = tokens.bootstrapToken
            if !bootstrapToken.isExpired {
                return try await refreshAndStoreBootstrapToken(bootstrapToken: bootstrapToken,
                                                               currentDeviceId: deviceId)
            }
            
            // All tokens have expired. Need to go through the bootstrap process from the beginning.
            await didExpireTokenWith(deviceId: deviceId)
            throw MPCConnectionServiceError.tokensExpired
        }
        
        await actionsQueuer.setTokenTask(deviceId: deviceId, task: getTokenTask)
        do {
            let value = try await getTokenTask.value
            await actionsQueuer.setTokenTask(deviceId: deviceId, task: nil)
            
            return value
        } catch {
            await actionsQueuer.setTokenTask(deviceId: deviceId, task: nil)
            throw error
        }
    }
    
    private func refreshAndStoreToken(refreshToken: JWToken,
                                      deviceId: String) async throws -> String {
        do {
            let refreshedTokens = try await networkService.refreshToken(refreshToken.jwt)
            try walletsDataStorage.storeAuthTokens(refreshedTokens, for: deviceId)
            return refreshedTokens.accessToken.jwt
        } catch {
            if case NetworkLayerError.badResponseOrStatusCode(_, _, let data) = error,
               let processingResponse = FB_UD_MPC.APIBadResponse.objectFromData(data),
               processingResponse.isInvalidCodeResponse {
                await didExpireTokenWith(deviceId: deviceId)
            }
            
            throw error
        }
    }
    
    private func refreshAndStoreBootstrapToken(bootstrapToken: JWToken,
                                       currentDeviceId: String) async throws -> String {
        do {
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
            
            try walletsDataStorage.storeAuthTokens(authTokens, for: currentDeviceId)
            return authTokens.accessToken.jwt
        } catch {
            await didExpireTokenWith(deviceId: currentDeviceId)
            throw error
        }
    }
    
    private func didExpireTokenWith(deviceId: String) async {
        await actionsQueuer.addRestoreDeviceId(deviceId)
        restoreWalletIfNeeded()
    }
    
    private func restoreWalletIfNeeded() {
        Task {
            guard let deviceIdToRestore = await actionsQueuer.getDeviceIdToRestoreAndStartIfNotInProgress() else { return }
            do {
                try await restoreOrRemoveWallet(deviceId: deviceIdToRestore)
            } catch { }

            await actionsQueuer.stopAndRemoveRestoreDeviceId(deviceIdToRestore)
            restoreWalletIfNeeded()
        }
    }
    
    private func restoreOrRemoveWallet(deviceId: String) async throws {
        let (wallet, metadataEntity) = try findUDWalletWith(deviceId: deviceId)
        let reconnectData = MPCWalletReconnectData(wallet: wallet,
                                                   email: metadataEntity.email)
        await uiHandler.askToReconnectMPCWallet(reconnectData)
    }
    
    private func findUDWalletWith(deviceId: String) throws -> (UDWallet, FB_UD_MPC.UDWalletMetadata) {
        let wallets = udWalletsService.getUserWallets()
        for wallet in wallets {
            if let metadata = wallet.mpcMetadata,
               let metadataEntity = try? getFBUDWalletMetadataFrom(walletMetadata: metadata),
               metadataEntity.deviceId == deviceId {
                return (wallet, metadataEntity)
            }
        }
        
        throw MPCConnectionServiceError.failedToFindUDWallet
    }
    
    private func performAuthErrorCatchingBlock<T>(connectedWalletDetails: FB_UD_MPC.ConnectedWalletDetails, _ block: ((String) async throws -> (T)) ) async throws -> T {
        do {
            let token = try await getFreshAccessTokenFor(wallet: connectedWalletDetails, forceRefresh: false)
            return try await block(token)
        } catch {
            if case NetworkLayerError.badResponseOrStatusCode(let code, _, _) = error,
               code == 403 {
                let token = try await getFreshAccessTokenFor(wallet: connectedWalletDetails, forceRefresh: true)
                return try await block(token)
            }
            
            throw error
        }
    }
}

// MARK: - Open methods
extension FB_UD_MPC.MPCConnectionService: UDWalletsServiceListener {
    func walletsDataUpdated(notification: UDWalletsServiceNotification) {
        switch notification {
        case .walletsUpdated, .reverseResolutionDomainChanged:
            return
        case .walletRemoved(let wallet):
            if let metadata = wallet.mpcMetadata,
               let walletDeviceId = (try? getFBUDWalletMetadataFrom(walletMetadata: metadata))?.deviceId {
                try? clearWalletDetails(deviceId: walletDeviceId)
            }
        }
    }
}

// MARK: - Queuing
extension FB_UD_MPC.MPCConnectionService {
    actor ActionsQueuer {
        private var ongoingDeviceIds: Set<String> = []
        private var tokenTasks: [String: Task<String, Error>] = [:]
        
        private var ongoingRestoreDeviceId: String? = nil
        private var deviceIdsToRestore: Set<String> = []
        
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
        
        func getTokenTask(deviceId: String) -> Task<String, Error>? {
            tokenTasks[deviceId]
        }

        func setTokenTask(deviceId: String,
                          task: Task<String, Error>?) {
            tokenTasks[deviceId] = task
        }
        
        func getDeviceIdToRestoreAndStartIfNotInProgress() -> String? {
            let isRestoringInProgress = isRestoringInProgress()
            guard !isRestoringInProgress,
                  let deviceIdToRestore = deviceIdsToRestore.first else { return nil }
            startRestoringDeviceId(deviceIdToRestore)
            return deviceIdToRestore
        }
        
        func addRestoreDeviceId(_ deviceId: String) {
            deviceIdsToRestore.insert(deviceId)
        }
      
        func stopAndRemoveRestoreDeviceId(_ deviceId: String) {
            deviceIdsToRestore.remove(deviceId)
            ongoingRestoreDeviceId = nil
        }
        
        private func startRestoringDeviceId(_ deviceId: String) {
            ongoingRestoreDeviceId = deviceId
        }
        
        private func isRestoringInProgress() -> Bool {
            ongoingRestoreDeviceId != nil
        }
    }
}
