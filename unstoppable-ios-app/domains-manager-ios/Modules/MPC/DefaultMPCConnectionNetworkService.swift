//
//  DefaultMPCConnectionNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

struct DefaultMPCConnectionNetworkService: MPCConnectionNetworkService {
    
    private let networkService = NetworkService()
    
    func sendBootstrapCodeTo(email: String) async throws {
        
        struct Body: Encodable {
            let walletExternalId: String
        }
        
        struct Response: Decodable {
            let code: String
        }
        
        let header = buildAuthBearerHeader(token: NetworkService.stagingWalletAPIAdminKey)
        let body = Body(walletExternalId: "wa-wt-96633a1c-2b70-47ca-a06f-01bef6b8f36b")
        let request = try APIRequest(urlString: MPCNetwork.URLSList.tempGetCodeURL,
                                     body: body,
                                     method: .post,
                                     headers: header)
        
        let response: Response = try await makeDecodableAPIRequest(request)
        
        logMPC("Did receive MPC bootstrap code: \(response.code)")
    }
    
    func submitBootstrapCode(_ code: String) async throws -> MPCBootstrapCodeSubmitResponse {
        struct Body: Encodable {
            let code: String
            var device: String? = nil
        }
        
        let body = Body(code: code)
        let request = try APIRequest(urlString: MPCNetwork.URLSList.submitCodeURL,
                                     body: body,
                                     method: .post)
        
        let response: MPCBootstrapCodeSubmitResponse = try await makeDecodableAPIRequest(request)
        return response
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
        try await makeAPIRequest(request)
    }
    
    func initTransactionWithNewKeyMaterials(accessToken: String) async throws -> MPCSetupTokenResponse {
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensSetupURL,
                                     method: .post,
                                     headers: headers)
        let response: MPCSetupTokenResponse = try await makeDecodableAPIRequest(request)
        
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
    
    private func checkTransactionWithNewKeyMaterialsStatus(accessToken: String) async throws -> MPCSetupTokenResponse {
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensSetupURL,
                                     method: .get,
                                     headers: headers)
        let response: MPCSetupTokenResponse = try await makeDecodableAPIRequest(request)
        
        return response
    }
    
    func confirmTransactionWithNewKeyMaterialsSigned(accessToken: String) async throws -> MPCSuccessAuthResponse {
        
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
        
        let response: MPCSuccessAuthResponse = try await makeDecodableAPIRequest(request)
        return response
    }
    
    func verifyAccessToken(_ accessToken: String) async throws {
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: MPCNetwork.URLSList.tokensVerifyURL,
                                     method: .get,
                                     headers: headers)
        try await makeAPIRequest(request)
    }
}

// MARK: - Private methods
private extension DefaultMPCConnectionNetworkService {
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
    
    func buildAuthBearerHeader(token: String) -> [String : String] {
        ["Authorization":"Bearer \(token)"]
    }
    
    enum MPCNetworkServiceError: String, LocalizedError {
        case waitForKeyMaterialsTransactionTimeout
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
