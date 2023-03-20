//
//  FirebaseAuthService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2023.
//

import UIKit

protocol FirebaseAuthServiceProtocol {
    
}

final class FirebaseAuthService {
    
    static let shared = FirebaseAuthService()
    
    private let keychainStorage: KeychainPrivateKeyStorage = .instance
    private let tokenKeychainKey: KeychainKey = .firebaseRefreshToken
    
    private init() { }
}

// MARK: - FirebaseAuthServiceProtocol
extension FirebaseAuthService: FirebaseAuthServiceProtocol {
    var refreshToken: String? {
        get { keychainStorage.retrieveValue(for: tokenKeychainKey) }
        set {
            if let newValue {
                keychainStorage.store(newValue, for: tokenKeychainKey)
            } else {
                keychainStorage.clear(for: tokenKeychainKey)
            }
        }
    }
    var isAuthorised: Bool { refreshToken != nil }
    var firebaseProfile: String { "" }
    
    func authorizeWith(email: String, password: String) async throws -> FirebaseTokenData {
        let authResponse = try await UDFirebaseSigner.shared.authorizeWith(email: email, password: password)
        
        saveAuthResponse(authResponse)
        return authResponse
    }
    
    func authorizeWithGoogleSignInIdToken(in viewController: UIViewController) async throws -> FirebaseTokenData {
        let googleSignInToken = try await UDGoogleSigner.shared.signIn(in: viewController)
        let authResponse = try await UDFirebaseSigner.shared.authorizeWithGoogleSignInIdToken(googleSignInToken)
        
        saveAuthResponse(authResponse)
        return authResponse
    }
    
    func authorizeWithTwitterCustomToken(in viewController: UIViewController) async throws -> FirebaseTokenData {
        let customToken = try await UDTwitterSigner.shared.signIn(in: viewController)
        let authResponse = try await UDFirebaseSigner.shared.authorizeWithTwitterCustomToken(customToken)
        
        saveAuthResponse(authResponse)
        return authResponse
    }
}

// MARK: - Private methods
private extension FirebaseAuthService {
    func saveAuthResponse(_ authResponse: FirebaseTokenData) {
        refreshToken = authResponse.refreshToken
    }
}
