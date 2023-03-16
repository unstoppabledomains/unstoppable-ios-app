//
//  UDFirebaseSigner.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2023.
//

import Foundation

final class UDFirebaseSigner: FirebaseAuthUtilitiesProtocol {
    
    static let shared = UDFirebaseSigner()
    
    private var googleAPIKey: String { FirebaseNetworkConfig.APIKey }
    
    private init() { }
    
}

// MARK: - Open methods
extension UDFirebaseSigner {
    func authorizeWith(email: String, password: String) async throws -> AuthResponse {
        struct RequestBody: Encodable {
            let email: String
            let password: String
            let returnSecureToken: Bool = true
        }
        
        let requestBody = RequestBody(email: email, password: password)
        return try await authorizeWith(requestBody: requestBody, accountType: .password)
    }
    
    func authorizeWithGoogleSignInIdToken(_ idToken: String) async throws -> AuthResponse {
        struct RequestBody: Encodable {
            var postBody: String
            var requestUri: String = "https://unstoppabledomains.com"
            var returnIdpCredential: Bool = true
            var returnSecureToken: Bool = true
        }
        let postBody = "id_token=\(idToken)&providerId=google.com"
        let requestBody = RequestBody(postBody: postBody)
        return try await authorizeWith(requestBody: requestBody, accountType: .idp)
    }
    
    func authorizeWithTwitterCustomToken(_ customToken: String) async throws -> AuthResponse {
        struct RequestBody: Encodable {
            var token: String
            var returnSecureToken: Bool = true
        }
        let requestBody = RequestBody(token: customToken)
        return try await authorizeWith(requestBody: requestBody, accountType: .customToken)
    }
    
    func refreshIDTokenWith(refreshToken: String) async throws -> AuthResponse {
        try await exchangeRefreshToken(refreshToken)
    }
}

// MARK: - Private methods
private extension UDFirebaseSigner {
    func authorizeWith(requestBody: any Encodable, accountType: GoogleSignInAccountType) async throws -> AuthResponse {
        let urlString = "https://identitytoolkit.googleapis.com/v1/accounts:\(accountType.rawValue)?key=\(googleAPIKey)"
        
        let requestURL = URL(string: urlString)!
        var request = URLRequest(url: requestURL)
        request.httpBody = try JSONEncoder().encode(requestBody)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let (data, _) = try await session.data(for: request)
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        return authResponse
    }
    
    func exchangeRefreshToken(_ refreshToken: String) async throws -> AuthResponse {
        let query: [String : String] = ["refresh_token" : refreshToken,
                                        "grant_type" : "refresh_token"]
        let queryString = buildURLQueryString(from: query)
        guard let httpData = queryString.data(using: .utf8) else { throw FirebaseAuthError.failedToBuildURL }
        
        let urlString = "https://securetoken.googleapis.com/v1/token?key=\(googleAPIKey)"
        
        let requestURL = URL(string: urlString)!
        var request = URLRequest(url: requestURL)
        request.httpBody = httpData
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let authResponse = try decoder.decode(AuthResponse.self, from: data)
        
        return authResponse
    }
}

// MARK: - Private methods
private extension UDFirebaseSigner {
    enum GoogleSignInAccountType: String {
        case idp = "signInWithIdp"
        case customToken = "signInWithCustomToken"
        case password = "signInWithPassword"
    }
}

// MARK: - Open methods
extension UDFirebaseSigner {
    struct AuthResponse: Codable {
        let idToken: String
        let refreshToken: String
        let expiresIn: String
    }
}
