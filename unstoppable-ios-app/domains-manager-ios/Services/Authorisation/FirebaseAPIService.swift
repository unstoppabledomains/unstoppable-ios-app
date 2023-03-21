//
//  FirebaseAPIService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.03.2023.
//

import UIKit

final class FirebaseAPIService {
    
    static let shared = FirebaseAPIService()
    private var tokenData: FirebaseTokenData?
}

// MARK: - Open methods
extension FirebaseAPIService {
    func authorizeWith(email: String, password: String) async throws {
        let tokenData = try await FirebaseAuthService.shared.authorizeWith(email: email, password: password)
        self.tokenData = tokenData
    }
    
    func authorizeWithGoogle(in viewController: UIViewController) async throws {
        let tokenData = try await FirebaseAuthService.shared.authorizeWithGoogleSignInIdToken(in: viewController)
        self.tokenData = tokenData
    }
    
    func authorizeWithTwitter(in viewController: UIViewController) async throws {
        let tokenData = try await FirebaseAuthService.shared.authorizeWithTwitterCustomToken(in: viewController)
        self.tokenData = tokenData
    }
    
    func getParkedDomains() async throws  {
        let url = URL(string: "\(baseAPIURL())user/domains?extension=All&page=1&perPage=50&status=all")!
        let request = APIRequest(url: url, body: "", method: .get)
        let data = try await makeFirebaseAPIDataRequest(request)
        print("Ha")
    }
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
        do {
            let firebaseAPIRequest = try await prepareFirebaseAPIRequest(apiRequest)
            return try await NetworkService().makeAPIRequest(firebaseAPIRequest)
        } catch {
            throw error
        }
    }
    
    func makeFirebaseDecodableAPIDataRequest<T: Decodable>(_ apiRequest: APIRequest) async throws -> T {
        let firebaseAPIRequest = try await prepareFirebaseAPIRequest(apiRequest)
        return try await NetworkService().makeDecodableAPIRequest(firebaseAPIRequest)
    }
    
    func prepareFirebaseAPIRequest(_ apiRequest: APIRequest) async throws -> APIRequest {
        guard let tokenData,
              let expirationDate = tokenData.expirationDate,
              expirationDate > Date() else {
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
        } else {
            throw FirebaseAuthError.firebaseUserNotAuthorisedInTheApp
        }
    }
    
    func refreshIdTokenWith(refreshToken: String) async throws {
        do {
            let authResponse = try await UDFirebaseSigner.shared.refreshIDTokenWith(refreshToken: refreshToken)
            guard let expiresIn = TimeInterval(authResponse.expiresIn) else { throw FirebaseAuthError.failedToGetTokenExpiresData }
            
            let expirationDate = Date().addingTimeInterval(expiresIn - 60) // Deduct 1 minute to ensure token won't expire in between of making request
            tokenData = FirebaseTokenData(idToken: authResponse.idToken,
                                          expiresIn: authResponse.expiresIn,
                                          expirationDate: expirationDate,
                                          refreshToken: authResponse.refreshToken)
        } catch FirebaseAuthError.refreshTokenExpired {
            FirebaseAuthService.shared.logout()
            throw FirebaseAuthError.refreshTokenExpired
        } catch {
            throw error
        }
    }
}

struct FirebaseTokenData: Codable {
    let idToken: String
    let expiresIn: String
    var expirationDate: Date?
    let refreshToken: String
}
