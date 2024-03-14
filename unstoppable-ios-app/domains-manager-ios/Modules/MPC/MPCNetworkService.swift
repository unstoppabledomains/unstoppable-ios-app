//
//  MPCNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import Foundation

enum MPCNetwork {
    enum URLSList {
        static var baseURL: String {
            "https://api-ud.staging.com"
        }
        
        static var v1URL: String { baseURL.appendingURLPathComponents("wallet", "v1") }
        
        static var tempGetCodeURL: String { v1URL.appendingURLPathComponents("admin", "auth", "bootstrap-code") }
        static var submitCodeURL: String { v1URL.appendingURLPathComponents("auth", "bootstrap") }
        static var rpcMessagesURL: String { v1URL.appendingURLPathComponents("rpc", "messages") }
        static var devicesBootstrapURL: String { v1URL.appendingURLPathComponents("devices", "bootstrap") }
        
        static var tokensURL: String { v1URL.appendingURLPathComponents("tokens") }
        static var tokensSetupURL: String { tokensURL.appendingURLPathComponents("setup") }
        static var tokensConfirmURL: String { tokensURL.appendingURLPathComponents("confirm") }
        static var tokensVerifyURL: String { tokensURL.appendingURLPathComponents("verify") }
        
    }
}

final class MPCNetworkService {
    
    private let networkService = NetworkService()
    
    static let shared = MPCNetworkService()
    
    private init() { }
    
}

// MARK: - Open methods
extension MPCNetworkService {
    /// Currently it will use admin route to generate code and log intro console.
    func sendBootstrapCodeTo(email: String) async throws {
        
        struct Body: Encodable {
            let walletExternalId: String
        }
        
        struct Response: Decodable {
            let code: String
        }
        
        let body = Body(walletExternalId: "123")
        let request = try APIRequest(urlString: MPCNetwork.URLSList.tempGetCodeURL,
                                     body: body,
                                     method: .post)
        
        let response: Response = try await networkService.makeDecodableAPIRequest(request)
        
        print("Did receive MPC bootstrap code: \(response.code)")
    }
    
    func signForNewDeviceWith(code: String,
                              recoveryPhrase: String) async throws {
        struct Body: Encodable {
            let code: String
            var device: String? = nil
        }
        
        struct Response: Decodable {
            let accessToken: String // temp access token
            let deviceId: String
        }
        
        let body = Body(code: code)
        let request = try APIRequest(urlString: MPCNetwork.URLSList.submitCodeURL,
                                     body: body,
                                     method: .post)
        
        let response: Response = try await networkService.makeDecodableAPIRequest(request)
        let accessToken = response.accessToken
        let deviceId = response.deviceId
        
        let rpcHandler = FireblocksRPCMessageHandler(authToken: accessToken)
        let fireblocksConnector = try FireblocksConnector(deviceId: deviceId,
                                                          messageHandler: rpcHandler)
        
        let requestId = try await fireblocksConnector.requestJoinExistingWallet()
        
        // Once we have the key material, now it’s time to get a full access token to the Wallets API. To prove that the key material is valid, you need to create a transaction to sign
        // Initialize a transaction with the Wallets API
        try await authNewDeviceWith(requestId: requestId,
                                    recoveryPhrase: recoveryPhrase,
                                    accessToken: accessToken)
        try await fireblocksConnector.waitForKeyIsReady()
        
        let transactionDetails = try await initTransactionWithNewKeyMaterials(accessToken: accessToken)
        
        /// Skipping this part because iOS doesn't have equal functions. To discuss with Wallet team
        /*
         const inProg = await sdk.getInProgressSigningTxId();
         if (inProg && inProg !== tx.transactionId) {
         this.logger.warn('Encountered in progress tx', { inProg });
         await sdk.stopInProgressSignTransaction();
         }
         */
        
        //    We have to wait for Fireblocks to also sign, so poll the Wallets API until the transaction is returned with the PENDING_SIGNATURE status
        try await waitForTransactionWithNewKeyMaterialsReady(accessToken: accessToken)
        
        let txId = transactionDetails.transactionId
        try await fireblocksConnector.signTransactionWith(txId: txId)
        
        //    Once it is pending a signature, sign with the Fireblocks NCW SDK and confirm with the Wallets API that you have signed. After confirmation is validated, you’ll be returned an access token, a refresh token and a bootstrap token.
        let finalAuthResponse = try await confirmTransactionWithNewKeyMaterialsSigned(accessToken: accessToken)
    }
    
}

// MARK: - Private methods
private extension MPCNetworkService {
    func authNewDeviceWith(requestId: String,
                           recoveryPhrase: String,
                           accessToken: String) async throws {
        struct Body: Encodable {
            let walletJoinRequestId: String
            var recoveryPhrase: String
        }
        
        let body = Body(walletJoinRequestId: requestId, recoveryPhrase: recoveryPhrase)
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: MPCNetwork.URLSList.devicesBootstrapURL,
                                     body: body,
                                     method: .post,
                                     headers: headers)
        try await networkService.makeAPIRequest(request)
    }
    
    func initTransactionWithNewKeyMaterials(accessToken: String) async throws -> SetupTokenResponse {
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensSetupURL,
                                     method: .post,
                                     headers: headers)
        let response: SetupTokenResponse = try await networkService.makeDecodableAPIRequest(request)
        
        return response
    }
    
    func waitForTransactionWithNewKeyMaterialsReady(accessToken: String) async throws {
        for _ in 0..<10 {
            let response = try await checkTransactionWithNewKeyMaterialsStatus(accessToken: accessToken)
            if response.isCompleted {
                return
            } else {
                await Task.sleep(seconds: 0.5)
            }
        }
        
        throw MPCNetworkServiceError.waitForKeyMaterialsTransactionTimeout
    }
    
    func checkTransactionWithNewKeyMaterialsStatus(accessToken: String) async throws -> SetupTokenResponse {
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensSetupURL,
                                     method: .get,
                                     headers: headers)
        let response: SetupTokenResponse = try await networkService.makeDecodableAPIRequest(request)
        
        return response
    }
    
    func confirmTransactionWithNewKeyMaterialsSigned(accessToken: String) async throws -> SuccessAuthResponse {
        
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
        
        let response: SuccessAuthResponse = try await networkService.makeDecodableAPIRequest(request)
        return response
    }
    
    func verifyAccessToken(_ accessToken: String) async throws {
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensVerifyURL,
                                     method: .get,
                                     headers: headers)
        try await networkService.makeAPIRequest(request)
    }
}

// MARK: - Private methods
private extension MPCNetworkService {
    func buildAuthBearerHeader(token: String) -> [String : String] {
        ["Authorization":"Bearer \(token)"]
    }
    
    struct SetupTokenResponse: Decodable {
        let transactionId: String // temp access token
        let status: String // 'QUEUED' | 'PENDING_SIGNATURE' | 'COMPLETED' | 'UNKNOWN';
        
        var isCompleted: Bool { status != "PENDING_SIGNATURE" }
    }
    
    struct SuccessAuthResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let bootstrapToken: String
    }
    
    enum MPCNetworkServiceError: String, LocalizedError {
        case waitForKeyMaterialsTransactionTimeout
        
        public var errorDescription: String? {
            return rawValue
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

