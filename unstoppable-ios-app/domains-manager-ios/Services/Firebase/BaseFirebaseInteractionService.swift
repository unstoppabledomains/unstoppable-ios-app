//
//  BaseFirebaseInteractionService.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 30.10.2023.
//

import Foundation

class BaseFirebaseInteractionService {
    
    enum URLSList {
        static var baseURL: String {
            NetworkConfig.migratedBaseUrl
        }
        static var baseAPIURL: String { baseURL.appendingURLPathComponent("api") }
    }
    
    let authHeaderKey = "auth-firebase-id-token"
    var tokenData: FirebaseTokenData?
    let firebaseAuthService: FirebaseAuthService
    let firebaseSigner: UDFirebaseSigner
    
    init(firebaseAuthService: FirebaseAuthService,
         firebaseSigner: UDFirebaseSigner) {
        self.firebaseAuthService = firebaseAuthService
        self.firebaseSigner = firebaseSigner
    }
    
    func logout() {
        tokenData = nil
        firebaseAuthService.logout()
    }
}

// MARK: - Open methods
extension BaseFirebaseInteractionService {
    func getIdToken() async throws -> String {
        guard let tokenData,
              let expirationDate = tokenData.expirationDate,
              expirationDate > Date() else {
            try await refreshIdTokenIfPossible()
            return try await getIdToken()
        }
        
        return tokenData.idToken
    }
    
    @discardableResult
    func makeFirebaseAPIDataRequest(_ apiRequest: APIRequest) async throws -> Data {
        do {
            let firebaseAPIRequest = try await prepareFirebaseAPIRequest(apiRequest)
            let response = try await NetworkService().makeAPIRequest(firebaseAPIRequest)
            return response
        } catch {
            Debugger.printInfo("Failed to make firebase api request: \(error.localizedDescription) for \(apiRequest.url)")
            throw error
        }
    }
    
    func makeFirebaseDecodableAPIDataRequest<T: Decodable>(_ apiRequest: APIRequest,
                                                           using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                                           dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) async throws -> T {
        let firebaseAPIRequest = try await prepareFirebaseAPIRequest(apiRequest)
        let response: T = try await NetworkService().makeDecodableAPIRequest(firebaseAPIRequest,
                                                                             using: keyDecodingStrategy,
                                                                             dateDecodingStrategy: dateDecodingStrategy)
        return response
    }
}

// MARK: - Private methods
private extension BaseFirebaseInteractionService {
    func prepareFirebaseAPIRequest(_ apiRequest: APIRequest) async throws -> APIRequest {
        let idToken = try await getIdToken()
        
        var headers = apiRequest.headers
        headers[authHeaderKey] = idToken
        let firebaseAPIRequest = APIRequest(url: apiRequest.url,
                                            headers: headers,
                                            body: apiRequest.body,
                                            method: apiRequest.method)
        
        return firebaseAPIRequest
    }
    
    func refreshIdTokenIfPossible() async throws {
        if let refreshToken = firebaseAuthService.refreshToken {
            try await refreshIdTokenWith(refreshToken: refreshToken)
        } else {
            throw FirebaseAuthError.firebaseUserNotAuthorisedInTheApp
        }
    }
    
    func refreshIdTokenWith(refreshToken: String) async throws {
        do {
            let authResponse = try await firebaseSigner.refreshIDTokenWith(refreshToken: refreshToken)
            guard let expiresIn = TimeInterval(authResponse.expiresIn) else { throw FirebaseAuthError.failedToGetTokenExpiresData }
            
            let expirationDate = Date().addingTimeInterval(expiresIn - 60) // Deduct 1 minute to ensure token won't expire in between of making request
            tokenData = FirebaseTokenData(idToken: authResponse.idToken,
                                          expiresIn: authResponse.expiresIn,
                                          expirationDate: expirationDate,
                                          refreshToken: authResponse.refreshToken)
        } catch FirebaseAuthError.refreshTokenExpired {
            logout()
            throw FirebaseAuthError.refreshTokenExpired
        } catch {
            throw error
        }
    }
}
