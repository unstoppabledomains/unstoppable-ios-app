//
//  FirebaseInteractionService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.03.2023.
//

import UIKit

final class FirebaseInteractionService {
    
    static let shared = FirebaseInteractionService()
    private var firebaseUser: FirebaseUser?
    private var tokenData: FirebaseTokenData?
    
    init() {
        Task {
            _ = try? await getUserProfile() // Refresh token and user profile 
        }
    }
}

// MARK: - Open methods
extension FirebaseInteractionService {
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
    
    func getUserProfile() async throws -> FirebaseUser {
        if let firebaseUser {
            return firebaseUser
        }
        let idToken = try await getIdToken()
        let firebaseUser = try await UDFirebaseSigner.shared.getUserProfile(idToken: idToken)
        self.firebaseUser = firebaseUser
        return firebaseUser
    }
    
    func getParkedDomains() async throws -> [FirebaseDomain] {
        struct Response: Codable {
            let domains: [FirebaseDomain]
        }
        
        let url = URL(string: "\(baseAPIURL())user/domains?extension=All&page=1&perPage=50&status=all")!
        let request = APIRequest(url: url, body: "", method: .get)
        let response: Response = try await makeFirebaseDecodableAPIDataRequest(request, dateDecodingStrategy: .defaultDateDecodingStrategy())
        
        return response.domains
    }
}

// MARK: - Private methods
private extension FirebaseInteractionService {
    func baseAPIURL() -> String {
        "https://\(NetworkConfig.migratedEndpoint)/api/"
    }
}

// MARK: - Private methods
private extension FirebaseInteractionService {
    func makeFirebaseAPIDataRequest(_ apiRequest: APIRequest) async throws -> Data {
        do {
            let firebaseAPIRequest = try await prepareFirebaseAPIRequest(apiRequest)
            return try await NetworkService().makeAPIRequest(firebaseAPIRequest)
        } catch {
            throw error
        }
    }
    
    func makeFirebaseDecodableAPIDataRequest<T: Decodable>(_ apiRequest: APIRequest,
                                                           using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                                           dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) async throws -> T {
        let firebaseAPIRequest = try await prepareFirebaseAPIRequest(apiRequest)
        return try await NetworkService().makeDecodableAPIRequest(firebaseAPIRequest,
                                                                  using: keyDecodingStrategy,
                                                                  dateDecodingStrategy: dateDecodingStrategy)
    }
    
    func prepareFirebaseAPIRequest(_ apiRequest: APIRequest) async throws -> APIRequest {
        let idToken = try await getIdToken()
         
        var headers = apiRequest.headers
        headers["auth-firebase-id-token"] = idToken
        let firebaseAPIRequest = APIRequest(url: apiRequest.url,
                                            headers: headers,
                                            body: apiRequest.body,
                                            method: apiRequest.method)
        
        return firebaseAPIRequest
    }
    
    func getIdToken() async throws -> String {
        guard let tokenData,
              let expirationDate = tokenData.expirationDate,
              expirationDate > Date() else {
            try await refreshIdTokenIfPossible()
            return try await getIdToken()
        }
        
        return tokenData.idToken
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
            logout()
            throw FirebaseAuthError.refreshTokenExpired
        } catch {
            throw error
        }
    }
    
    func logout() {
        FirebaseAuthService.shared.logout()
        firebaseUser = nil
    }
}

struct FirebaseTokenData: Codable {
    let idToken: String
    let expiresIn: String
    var expirationDate: Date?
    let refreshToken: String
}

struct FirebaseUser: Codable {
    var email: String?
}

struct FirebaseDomain: Codable {
    var claimStatus: String
    var internalCustody: Bool
    var parkingExpiresAt: Date?
    var domainId: Int
    var blockchain: String
    var projectedBlockchain: String
    var geminiCustody: String?
    var geminiCustodyExpiresAt: Date?
    var name: String
    var ownerAddress: String
    var logicalOwnerAddress: String
    var type: String
}

