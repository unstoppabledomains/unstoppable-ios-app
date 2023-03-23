//
//  FirebaseAuthService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2023.
//

import UIKit

protocol FirebaseAuthServiceProtocol {
    var isAuthorised: Bool { get }
}

final class FirebaseAuthService {
        
    private let keychainStorage: KeychainPrivateKeyStorage = .instance
    private let tokenKeychainKey: KeychainKey = .firebaseRefreshToken
    private let twitterSigner = UDTwitterSigner()
    private let googleSigner = UDGoogleSigner()
    private let firebaseSigner: UDFirebaseSigner

    init(firebaseSigner: UDFirebaseSigner) {
        self.firebaseSigner = firebaseSigner
    }
}

// MARK: - FirebaseAuthServiceProtocol
extension FirebaseAuthService: FirebaseAuthServiceProtocol {
    var refreshToken: String? {
        get { keychainStorage.retrieveValue(for: tokenKeychainKey, isCritical: false) }
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
        let authResponse = try await firebaseSigner.authorizeWith(email: email, password: password)
        
        saveAuthResponse(authResponse)
        return authResponse
    }
    
    func authorizeWithGoogleSignInIdToken(in viewController: UIViewController) async throws -> FirebaseTokenData {
        let googleSignInToken = try await googleSigner.signIn(in: viewController)
        let authResponse = try await firebaseSigner.authorizeWithGoogleSignInIdToken(googleSignInToken)
        
        saveAuthResponse(authResponse)
        return authResponse
    }
    
    func authorizeWithTwitterCustomToken(in viewController: UIViewController) async throws -> FirebaseTokenData {
        let customToken = try await twitterSigner.signIn(in: viewController)
        let authResponse = try await firebaseSigner.authorizeWithTwitterCustomToken(customToken)
        
        saveAuthResponse(authResponse)
        return authResponse
    }
    
    func logout() {
        refreshToken = nil 
    }
}

// MARK: - Private methods
private extension FirebaseAuthService {
    func saveAuthResponse(_ authResponse: FirebaseTokenData) {
        refreshToken = authResponse.refreshToken
    }
}
