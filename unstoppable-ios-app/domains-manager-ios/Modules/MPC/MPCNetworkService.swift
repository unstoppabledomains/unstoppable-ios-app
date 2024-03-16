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
            "https://api.ud-staging.com" // NetworkConfig.migratedBaseUrl
        }
        
        static var v1URL: String { baseURL.appendingURLPathComponents("wallet", "v1") }
        
        static var tempGetCodeURL: String { v1URL.appendingURLPathComponents("admin", "auth", "bootstrap-code") }
        static var submitCodeURL: String { v1URL.appendingURLPathComponents("auth", "bootstrap") }
        static var rpcMessagesURL: String { v1URL.appendingURLPathComponents("rpc", "messages") }
        static var devicesBootstrapURL: String { v1URL.appendingURLPathComponents("auth", "devices", "bootstrap") }
        
        static var tokensURL: String { v1URL.appendingURLPathComponents("auth", "tokens") }
        static var tokensSetupURL: String { tokensURL.appendingURLPathComponents("setup") }
        static var tokensConfirmURL: String { tokensURL.appendingURLPathComponents("confirm") }
        static var tokensVerifyURL: String { tokensURL.appendingURLPathComponents("verify") }
        
    }
}

func logMPC(_ message: String) {
    print("MPC: - \(message)")
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
        
        let header = buildAuthBearerHeader(token: NetworkService.stagingWalletAPIAdminKey)
        let body = Body(walletExternalId: "wa-wt-d890e86a-7680-4c6a-9d23-e80e00be44d9")
        let request = try APIRequest(urlString: MPCNetwork.URLSList.tempGetCodeURL,
                                     body: body,
                                     method: .post,
                                     headers: header)
        
        let response: Response = try await makeDecodableAPIRequest(request)
        
        logMPC("Did receive MPC bootstrap code: \(response.code)")
    }

    func signForNewDeviceWith(code: String,
                              recoveryPhrase: String) -> AsyncThrowingStream<SetupMPCWalletStep, Error> {
        AsyncThrowingStream { continuation in
            Task {
                struct Body: Encodable {
                    let code: String
                    var device: String? = nil
                }
                
                struct Response: Decodable {
                    let accessToken: String // temp access token
                    let deviceId: String
                }
                
                continuation.yield(.submittingCode)
                logMPC("Will submit code \(code). recoveryPhrase: \(recoveryPhrase)")
                let body = Body(code: code)
                let request = try APIRequest(urlString: MPCNetwork.URLSList.submitCodeURL,
                                             body: body,
                                             method: .post)
                
                let response: Response = try await makeDecodableAPIRequest(request)
                logMPC("Did submit code \(code)")
                let accessToken = response.accessToken
                let deviceId = response.deviceId
                
                continuation.yield(.initialiseFireblocks)
                let rpcHandler = FireblocksBootstrapRPCMessageHandler(authToken: accessToken)
                logMPC("Will create fireblocks connector")
                let fireblocksConnector = try FireblocksConnector(deviceId: deviceId,
                                                                  messageHandler: rpcHandler)
                fireblocksConnector.stopJoinWallet()
                logMPC("Did create fireblocks connector")
                logMPC("Will request to join existing wallet")
                do {
                    continuation.yield(.requestingToJoinExistingWallet)
                    let requestId = try await fireblocksConnector.requestJoinExistingWallet()
                    logMPC("Will auth new device with request id: \(requestId)")
                    // Once we have the key material, now it’s time to get a full access token to the Wallets API. To prove that the key material is valid, you need to create a transaction to sign
                    // Initialize a transaction with the Wallets API
                    continuation.yield(.authorisingNewDevice)
                    try await authNewDeviceWith(requestId: requestId,
                                                recoveryPhrase: recoveryPhrase,
                                                accessToken: accessToken)
                    logMPC("Did auth new device with request id: \(requestId)")
                    logMPC("Will wait for key is ready")
                    continuation.yield(.waitingForKeysIsReady)
                    try await fireblocksConnector.waitForKeyIsReady()
                    
                    logMPC("Will init transaction with new key materials")
                    continuation.yield(.initialiseTransaction)
                    let transactionDetails = try await initTransactionWithNewKeyMaterials(accessToken: accessToken)
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
                    try await waitForTransactionWithNewKeyMaterialsReady(accessToken: accessToken)
                    
                    logMPC("Will sign transaction with fireblocks. txId: \(txId)")
                    continuation.yield(.signingTransaction)
                    try await fireblocksConnector.signTransactionWith(txId: txId)
                    
                    //    Once it is pending a signature, sign with the Fireblocks NCW SDK and confirm with the Wallets API that you have signed. After confirmation is validated, you’ll be returned an access token, a refresh token and a bootstrap token.
                    logMPC("Will confirm transaction is signed")
                    continuation.yield(.confirmingTransaction)
                    let finalAuthResponse = try await confirmTransactionWithNewKeyMaterialsSigned(accessToken: accessToken)
                    logMPC("Did confirm transaction is signed")
                    
                    logMPC("Will verify final response \(finalAuthResponse)")
                    continuation.yield(.verifyingAccessToken)
                    try await verifyAccessToken(finalAuthResponse.accessToken)
                    logMPC("Did verify verify final response \(finalAuthResponse) success")
                    
                    let mpcWallet = UDMPCWallet(deviceId: deviceId,
                                                tokens: .init(refreshToken: finalAuthResponse.refreshToken,
                                                              bootstrapToken: finalAuthResponse.bootstrapToken))
                    continuation.yield(.finished(mpcWallet))
                    continuation.finish()
                } catch {
                    fireblocksConnector.stopJoinWallet()
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Private methods
private extension MPCNetworkService {
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
        try await makeAPIRequest(request)
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
            if response.isCompleted {
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
    
    func checkTransactionWithNewKeyMaterialsStatus(accessToken: String) async throws -> SetupTokenResponse {
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensSetupURL,
                                     method: .get,
                                     headers: headers)
        let response: SetupTokenResponse = try await makeDecodableAPIRequest(request)
        
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
        
        let response: SuccessAuthResponse = try await makeDecodableAPIRequest(request)
        return response
    }
    
    func verifyAccessToken(_ accessToken: String) async throws {
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensVerifyURL,
                                     method: .get,
                                     headers: headers)
        try await makeAPIRequest(request)
    }
    
    
    func makeDecodableAPIRequest<T: Decodable>(_ apiRequest: APIRequest) async throws -> T {
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
    func makeAPIRequest(_ apiRequest: APIRequest) async throws -> Data {
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
}

// MARK: - Private methods
private extension MPCNetworkService {
    func buildAuthBearerHeader(token: String) -> [String : String] {
        ["Authorization":"Bearer \(token)"]
    }
    
    struct SetupTokenResponse: Decodable {
        let transactionId: String // temp access token
        let status: String // 'QUEUED' | 'PENDING_SIGNATURE' | 'COMPLETED' | 'UNKNOWN';
        
        var isCompleted: Bool { status == "PENDING_SIGNATURE" }
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


enum SetupMPCWalletStep {
    case submittingCode
    case initialiseFireblocks
    case requestingToJoinExistingWallet
    case authorisingNewDevice
    case waitingForKeysIsReady
    case initialiseTransaction
    case waitingForTransactionIsReady
    case signingTransaction
    case confirmingTransaction
    case verifyingAccessToken
    case finished(UDMPCWallet)
    
    var title: String {
        switch self {
        case .submittingCode:
            "Submitting code"
        case .initialiseFireblocks:
            "Initialise Fireblocks"
        case .requestingToJoinExistingWallet:
            "Requesting to join existing wallet"
        case .authorisingNewDevice:
            "Authorising new device"
        case .waitingForKeysIsReady:
            "Waiting for keys is ready"
        case .initialiseTransaction:
            "Initialise transaction"
        case .waitingForTransactionIsReady:
            "Waiting for transaction is ready"
        case .signingTransaction:
            "Signing transaction"
        case .confirmingTransaction:
            "Confirming transaction"
        case .verifyingAccessToken:
            "Verifying access token"
        case .finished(let uDMPCWallet):
            "Finished"
        }
    }
}
