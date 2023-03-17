//
//  FirebaseAPIService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.03.2023.
//

import Foundation

final class FirebaseAPIService {
    private var tokenData: FirebaseTokenData?
}

// MARK: - Open methods
extension FirebaseAPIService {
    
}

// MARK: - Private methods
private extension FirebaseAPIService {
    func baseAPIURL() -> String {
        "https://\(NetworkConfig.migratedEndpoint)/api/"
    }
}

// MARK: - Private methods
private extension FirebaseAPIService {
    func makeFirebaseAPIDataRequest(_ apiRequest: APIRequest) async throws -> Data {
        let firebaseAPIRequest = try await prepareFirebaseAPIRequest(apiRequest)
        return try await NetworkService().makeAPIRequest(firebaseAPIRequest)
    }
    
    func makeFirebaseDecodableAPIDataRequest<T: Decodable>(_ apiRequest: APIRequest) async throws -> T {
        let firebaseAPIRequest = try await prepareFirebaseAPIRequest(apiRequest)
        return try await NetworkService().makeDecodableAPIRequest(firebaseAPIRequest)
    }
    
    func prepareFirebaseAPIRequest(_ apiRequest: APIRequest) async throws -> APIRequest {
        guard let tokenData,
              tokenData.expirationDate > Date() else {
            try await refreshIdTokenIfPossible()
            return try await prepareFirebaseAPIRequest(apiRequest)
        }
         
        var headers = apiRequest.headers
        headers["auth-firebase-id-token"] = tokenData.idToken
        let firebaseAPIRequest = APIRequest(url: apiRequest.url,
                                            headers: headers,
                                            body: apiRequest.body,
                                            method: apiRequest.method)
        
        return firebaseAPIRequest
    }
    
    func refreshIdTokenIfPossible() async throws {
        if let refreshToken = FirebaseAuthService.shared.refreshToken {
            try await refreshIdTokenWith(refreshToken: refreshToken)
        }
        
        throw FirebaseAPIError.firebaseUserNotAuthorisedInTheApp
    }
    
    func refreshIdTokenWith(refreshToken: String) async throws {
        let authResponse = try await UDFirebaseSigner.shared.refreshIDTokenWith(refreshToken: refreshToken)
        guard let expiresIn = TimeInterval(authResponse.expiresIn) else { throw FirebaseAPIError.failedToGetTokenExpiresData }
        
        let expirationDate = Date().addingTimeInterval(expiresIn - 10) // Deduct 10 seconds to ensure token won't expire in between of request
        tokenData = FirebaseTokenData(idToken: authResponse.idToken,
                                      expirationDate: expirationDate,
                                      refreshToken: authResponse.refreshToken)
    }
}

// MARK: - Private methods
private extension FirebaseAPIService {
    struct FirebaseTokenData {
        let idToken: String
        let expirationDate: Date
        let refreshToken: String
    }
    
    enum FirebaseAPIError: Error {
        case failedToGetTokenExpiresData
        case firebaseUserNotAuthorisedInTheApp
    }
}
