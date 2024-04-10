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
            
            let body = Body()
            let headers = buildAuthBearerHeader(token: accessToken)
            let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensConfirmURL,
                                         body: body,
                                         method: .post,
                                         headers: headers)
            
            let response: AuthTokens = try await makeDecodableAPIRequest(request)
            return response
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
            if let networkError = error as? NetworkLayerError,
               case .badResponseOrStatusCode(let errorCode, _) = networkError,
               errorCode == code {
                return true
            }
            return false
        }
        
        private enum MPCNetworkServiceError: String, LocalizedError {
            case waitForKeyMaterialsTransactionTimeout
            
            public var errorDescription: String? {
                return rawValue
            }
        }
    }
}
