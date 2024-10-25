//
//  DefaultMPCConnectionNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

extension FB_UD_MPC {
    struct DefaultMPCConnectionNetworkService: MPCConnectionNetworkService, NetworkBearerAuthorisationHeaderBuilder {
        
        private let networkService = NetworkService()
        
        func sendBootstrapCodeTo(email: String) async throws {
            
            struct Body: Encodable {
                let email: String
            }
            
            let body = Body(email: email)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.getCodeOnEmailURL,
                                         body: body,
                                         method: .post)
            
            try await makeAPIRequest(request)
        }
        
        func submitBootstrapCode(_ code: String) async throws -> BootstrapCodeSubmitResponse {
            struct Body: Encodable {
                let code: String
                var device: String? = nil
            }
            
            let body = Body(code: code)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.submitCodeURL,
                                         body: body,
                                         method: .post)
            
            do {
                let response: BootstrapCodeSubmitResponse = try await makeDecodableAPIRequest(request)
                return response
            } catch {
                if isNetworkError(error, withCode: 400) {
                    throw MPCWalletError.incorrectCode
                }
                throw error
            }
        }
        
        func authNewDeviceWith(requestId: String,
                               recoveryPhrase: String,
                               accessToken: String) async throws {
            struct Body: Encodable {
                let walletJoinRequestId: String
                var recoveryPassphrase: String
            }
            
            let body = Body(walletJoinRequestId: requestId, recoveryPassphrase: recoveryPhrase)
            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.devicesBootstrapURL,
                                         body: body,
                                         method: .post,
                                         headers: headers)
            do {
                try await makeAPIRequest(request)
            } catch {
                if isNetworkError(error, withCode: 400) {
                    throw MPCWalletError.incorrectPassword
                }
                throw error
            }
        }
        
        func initTransactionWithNewKeyMaterials(accessToken: String) async throws -> SetupTokenResponse {
            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensSetupURL,
                                         method: .post,
                                         headers: headers)
            let response: SetupTokenResponse = try await makeDecodableAPIRequest(request)
            
            return response
        }
        
        func waitForTransactionWithNewKeyMaterialsReady(accessToken: String) async throws {
            for i in 0..<50 {
                logMPC("Will check for transaction is ready attempt \(i + 1)")
                let response = try await checkTransactionWithNewKeyMaterialsStatus(accessToken: accessToken)
                if response.isReady {
                    logMPC("Transaction is ready")
                    return
                } else {
                    logMPC("Transaction is not ready. Will wait more.")
                    await Task.sleep(seconds: 0.5)
                }
            }
            
            logMPC("Abort waiting for transaction ready due to timeout")
            throw MPCNetworkServiceError.waitForKeyMaterialsTransactionTimeout
        }
        
        private func checkTransactionWithNewKeyMaterialsStatus(accessToken: String) async throws -> SetupTokenResponse {
            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensSetupURL,
                                         method: .get,
                                         headers: headers)
            let response: SetupTokenResponse = try await makeDecodableAPIRequest(request)
            
            return response
        }
        
        func confirmTransactionWithNewKeyMaterialsSigned(accessToken: String) async throws -> AuthTokens {
            struct Body: Encodable {
                var includeRefreshToken: Bool = true
                var includeBootstrapToken: Bool = true
            }
            
            do {
                let body = Body()
                let headers = buildAuthBearerHeader(token: accessToken)
                let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensConfirmURL,
                                             body: body,
                                             method: .post,
                                             headers: headers)
                
                let response: AuthTokens = try await makeDecodableAPIRequest(request)
                return response
            } catch NetworkLayerError.badResponseOrStatusCode(let code, let message, let data) {
                if let processingResponse = APIBadResponse.objectFromData(data),
                   processingResponse.code == TransactionOperationStatus.processing.rawValue {
                    logMPC("Will wait for processing tx and try to confirm again")
                    await Task.sleep(seconds: 0.5)
                    return try await confirmTransactionWithNewKeyMaterialsSigned(accessToken: accessToken)
                } else {
                    throw NetworkLayerError.badResponseOrStatusCode(code: code,
                                                                    message: message,
                                                                    data: data)
                }
            } catch {
                throw error
            }
        }
        
        func verifyAccessToken(_ accessToken: String) async throws {
            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensVerifyURL,
                                         method: .get,
                                         headers: headers)
            try await makeAPIRequest(request)
        }
        
        func refreshToken(_ refreshToken: String) async throws -> AuthTokens {
            struct Body: Encodable {
                var refreshToken: String
                var includeRefreshToken: Bool = true
                var includeBootstrapToken: Bool = true
            }
            
            let body = Body(refreshToken: refreshToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensRefreshURL,
                                         body: body,
                                         method: .post)
            
            let response: AuthTokens = try await makeDecodableAPIRequest(request)
            return response
        }
        
        func refreshBootstrapToken(_ bootstrapToken: String) async throws -> RefreshBootstrapTokenResponse {
            struct Body: Encodable {
                var bootstrapToken: String
            }
            
            let body = Body(bootstrapToken: bootstrapToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensBootstrapURL,
                                         body: body,
                                         method: .post)
            
            let response: RefreshBootstrapTokenResponse = try await makeDecodableAPIRequest(request)
            return response
        }
        
        func getAccounts(accessToken: String) async throws -> WalletAccountsResponse {
            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.accountsURL,
                                         method: .get,
                                         headers: headers)
            
            let response: WalletAccountsResponse = try await makeDecodableAPIRequest(request)
            return response
        }
        
        func getAccountAssets(accountId: String,
                              accessToken: String,
                              includeBalances: Bool) async throws -> WalletAccountAssetsResponse {
            let headers = buildAuthBearerHeader(token: accessToken)
            var url = MPCNetwork.URLSList.accountAssetsURL(accountId: accountId)
            if includeBalances {
                url += "?$expand=balance"
            }
            let request = try APIRequest(urlString: url,
                                         method: .get,
                                         headers: headers)
            
            let response: WalletAccountAssetsResponse = try await makeDecodableAPIRequest(request)
            return response
        }
        
        func getSupportedBlockchainAssets(accessToken: String) async throws -> SupportedBlockchainAssetsResponse {
            let headers = buildAuthBearerHeader(token: accessToken)
            let url = MPCNetwork.URLSList.supportedBlockchainsURL
            let request = try APIRequest(urlString: url,
                                         method: .get,
                                         headers: headers)
            
            let response: SupportedBlockchainAssetsResponse = try await makeDecodableAPIRequest(request)
            return response
        }
        
        func startMessageSigning(accessToken: String,
                                 accountId: String,
                                 assetId: String,
                                 message: String,
                                 signingType: MessageSigningType) async throws -> OperationDetails {
            let body = try createMessageSigningPayloadFor(message: message, signingType: signingType)
            let headers = buildAuthBearerHeader(token: accessToken)
            let url = MPCNetwork.URLSList.assetSignaturesURL(accountId: accountId, assetId: assetId)
            let request = try APIRequest(urlString: url,
                                         body: body,
                                         method: .post,
                                         headers: headers)
            return try await runStartOperationUsing(request: request)
        }
        
        private func createMessageSigningPayloadFor(message: String,
                                                    signingType: MessageSigningType) throws -> any Codable {
            switch signingType {
            case .personalSign(let encoding):
                struct RequestBody: Codable {
                    let message: String
                    let encoding: SignMessageEncoding
                }
                return RequestBody(message: message, encoding: encoding)
            case .typedData:
                enum RequestType: String, Codable {
                    case erc712
                }
                
                enum RequestEncodingType: String, Codable {
                    case hex
                }
                
                struct RequestBody: Codable {
                    let message: String
                    var type: RequestType = .erc712
                    var encoding: RequestEncodingType = .hex
                }
                return RequestBody(message: message.hexRepresentation)
            }
        }
        
        func startAssetTransfer(accessToken: String,
                                accountId: String,
                                assetId: String,
                                destinationAddress: String,
                                amount: String) async throws -> OperationDetails {
            struct RequestBody: Codable {
                let destinationAddress: String
                let amount: String
            }
            
            let body = RequestBody(destinationAddress: destinationAddress, amount: amount)
            let headers = buildAuthBearerHeader(token: accessToken)
            let url = MPCNetwork.URLSList.assetTransfersURL(accountId: accountId, assetId: assetId)
            let request = try APIRequest(urlString: url,
                                         body: body,
                                         method: .post,
                                         headers: headers)
            return try await runStartOperationUsing(request: request)
        }
        
        func startSendETHTransaction(accessToken: String,
                                     accountId: String,
                                     assetId: String,
                                     destinationAddress: String,
                                     data: String,
                                     value: String) async throws -> OperationDetails {
            struct RequestBody: Codable {
                let destinationAddress: String
                let data: String
                let value: String
            }
            
            let body = RequestBody(destinationAddress: destinationAddress,
                                   data: data,
                                   value: value)
            let headers = buildAuthBearerHeader(token: accessToken)
            let url = MPCNetwork.URLSList.assetTransactionsURL(accountId: accountId, assetId: assetId)
            let request = try APIRequest(urlString: url,
                                         body: body,
                                         method: .post,
                                         headers: headers)
            return try await runStartOperationUsing(request: request)
        }
        
        private func runStartOperationUsing(request: APIRequest) async throws -> OperationDetails {
            struct Response: Codable {
                let operation: OperationDetails
            }
            
            let response: Response = try await makeDecodableAPIRequest(request)
            return response.operation
        }
        
        func waitForOperationReadyAndGetTxId(accessToken: String,
                                             operationId: String) async throws -> OperationReadyResponse {
            let operation = try await waitForOperationStatuses(accessToken: accessToken,
                                                               operationId: operationId,
                                                               statuses: [.signatureRequired, .completed])
            if operation.status == TransactionOperationStatus.signatureRequired.rawValue {
                guard let transactionId = operation.transaction?.externalVendorTransactionId else {
                    throw MPCNetworkServiceError.missingVendorIdInSignTransactionOperation
                }
                return .txReady(txId: transactionId)
            } else {
                if let signature = operation.result?.signature {
                    return .signed(signature: signature)
                } else if let txHash = operation.transaction?.id {
                    return .finished(txHash: txHash)
                }
                throw MPCNetworkServiceError.completedTransactionMissingResultValue
            }
        }
        
        func waitForOperationSignedAndGetTxSignature(accessToken: String,
                                                     operationId: String) async throws -> String {
            let operation = try await waitForOperationStatuses(accessToken: accessToken,
                                                               operationId: operationId,
                                                               statuses: [.completed])
            guard let signature = operation.result?.signature else {
                throw MPCNetworkServiceError.missingSignatureInSignTransactionOperation
            }
            return signature
        }
        
        func waitForTxCompletedAndGetHash(accessToken: String,
                                          operationId: String) async throws -> String {
            let operation = try await waitForOperationStatuses(accessToken: accessToken,
                                                               operationId: operationId,
                                                               statuses: [.processing, .completed])
            guard let txHash = operation.transaction?.id else {
                throw MPCNetworkServiceError.missingTxIdInTransactionOperation
            }
            return txHash
        }
        
        func fetchCryptoPortfolioForMPC(wallet: String, accessToken: String) async throws -> [WalletTokenPortfolio] {
            try await networkService.fetchCryptoPortfolioForMPC(wallet: wallet, accessToken: accessToken)
        }
        
        func waitForOperationCompleted(accessToken: String,
                                       operationId: String) async throws {
            try await waitForOperationStatuses(accessToken: accessToken,
                                               operationId: operationId,
                                               statuses: [.completed])
        }
        
        func get2FAStatus(accessToken: String) async throws -> Bool {
            struct Response: Codable {
                let otpEnabled: Bool
            }

            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.otpURL,
                                         method: .get,
                                         headers: headers)
            let response: Response = try await makeDecodableAPIRequest(request)
            return response.otpEnabled
        }

        func enable2FA(accessToken: String) async throws -> String {
            struct Response: Codable {
                let secret: String
            }
            
            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.otpURL,
                                         method: .post,
                                         headers: headers)
            let response: Response = try await makeDecodableAPIRequest(request)
            return response.secret
        }
        
        func verify2FAToken(accessToken: String, token: String) async throws {
            struct RequestBody: Codable {
                let token: String
            }
            
            let body = RequestBody(token: token)
            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.otpVerificationURL,
                                         body: body,
                                         method: .post,
                                         headers: headers)
            try await makeAPIRequest(request)
        }

        func disable2FA(accessToken: String,
                         token: String) async throws {
            struct RequestBody: Codable {
                let token: String
            }
            
            let body = RequestBody(token: token)
            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.otpURL,
                                         body: body,
                                         method: .delete,
                                         headers: headers)
            try await makeAPIRequest(request)
        }

        @discardableResult
        private func waitForOperationStatuses(accessToken: String,
                                              operationId: String,
                                              statuses: Set<TransactionOperationStatus>) async throws -> OperationDetails {
            let statuses = statuses.map { $0.rawValue }
            for _ in 0..<120 {
                let operation = try await getOperationWith(accessToken: accessToken,
                                                           operationId: operationId)
                if statuses.contains(operation.status) {
                    return operation
                } else if operation.status == TransactionOperationStatus.failed.rawValue {
                    throw MPCNetworkServiceError.operationFailed
                } else {
                    await Task.sleep(seconds: 0.5)
                }
            }
            
            throw MPCNetworkServiceError.waitForKeyOperationStatusTimeout
        }
        
        private func getOperationWith(accessToken: String,
                                      operationId: String) async throws -> OperationDetails {
            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.operationURL(operationId: operationId),
                                         method: .get,
                                         headers: headers)
            let response: OperationDetails = try await makeDecodableAPIRequest(request)
            
            return response
        }
        
        
        func getAssetTransferEstimations(accessToken: String,
                                         accountId: String,
                                         assetId: String,
                                         destinationAddress: String,
                                         amount: String) async throws -> NetworkFeeResponse {
            struct RequestBody: Codable {
                let destinationAddress: String
                let amount: String
            }
            
            let body = RequestBody(destinationAddress: destinationAddress, amount: amount)
            let headers = buildAuthBearerHeader(token: accessToken)
            let url = MPCNetwork.URLSList.assetTransfersEstimatesURL(accountId: accountId, assetId: assetId)
            let request = try APIRequest(urlString: url,
                                         body: body,
                                         method: .post,
                                         headers: headers)
            let response: NetworkFeeResponse = try await makeDecodableAPIRequest(request)
            return response
        }
        
        func requestRecovery(_ accessToken: String,
                             password: String) async throws {
            struct RequestBody: Codable {
                let recoveryPassphrase: String
            }
            
            let url = MPCNetwork.URLSList.recoveryURL
            let body = RequestBody(recoveryPassphrase: password)
            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: url,
                                         body: body,
                                         method: .post,
                                         headers: headers)
            try await makeAPIRequest(request)
        }
        
        func resetPassword(accessToken: String,
                           recoveryToken: String,
                           newRecoveryPhrase: String,
                           requestId: String) async throws {
            struct RequestBody: Codable {
                let recoveryToken: String
                let newRecoveryPassphrase: String
                let walletJoinRequestId: String
            }

            let url = MPCNetwork.URLSList.devicesRecoverURL
            let body = RequestBody(recoveryToken: recoveryToken,
                                   newRecoveryPassphrase: newRecoveryPhrase,
                                   walletJoinRequestId: requestId)
            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: url,
                                         body: body,
                                         method: .post,
                                         headers: headers)
            try await makeAPIRequest(request)
        }
        
        // MARK: - Private methods
        private func makeDecodableAPIRequest<T: Decodable>(_ apiRequest: APIRequest) async throws -> T {
            do {
                logMPC("Will make decodable request \(apiRequest)")
                let response: T = try await networkService.makeDecodableAPIRequest(apiRequest)
                logMPC("Did receive response: \(response)")
                
                return response
            } catch {
                logMPC("Did fail to make request \(apiRequest) with error: \(error.localizedDescription)")
                throw error
            }
        }
        
        @discardableResult
        private func makeAPIRequest(_ apiRequest: APIRequest) async throws -> Data {
            do {
                logMPC("Will make decodable request \(apiRequest)")
                
                let response = try await networkService.makeAPIRequest(apiRequest)
                logMPC("Did receive response: \(String(data: response, encoding: .utf8) ?? "-")")
                
                return response
            } catch {
                logMPC("Did fail to make request \(apiRequest) with error: \(error.localizedDescription)")
                throw error
            }
        }
        
        private func isNetworkError(_ error: Error, withCode code: Int) -> Bool {
            error.isNetworkError(withCode: code)
        }
        
        private enum MPCNetworkServiceError: String, LocalizedError {
            case waitForKeyMaterialsTransactionTimeout
            case waitForKeyOperationStatusTimeout
            case missingVendorIdInSignTransactionOperation
            case missingSignatureInSignTransactionOperation
            case completedTransactionMissingResultValue
            case missingTxIdInTransactionOperation
            case badRequestData
            case operationFailed
            
            public var errorDescription: String? {
                return rawValue
            }
        }
    }
}
