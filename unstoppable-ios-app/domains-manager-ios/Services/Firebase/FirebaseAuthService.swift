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
        
    static let shared = FirebaseAuthService(firebaseSigner: UDFirebaseSigner.shared)
    
    private let keychainStorage = UserDefaults.standard
    private let tokenKeychainKey: String = "firebaseRefreshToken"
    private let twitterSigner = UDTwitterSigner()
    private let googleSigner = UDGoogleSigner()
    private let walletSigner = UDWalletSigner()
    private let firebaseSigner: UDFirebaseSigner

    init(firebaseSigner: UDFirebaseSigner) {
        self.firebaseSigner = firebaseSigner
    }
}

// MARK: - FirebaseAuthServiceProtocol
extension FirebaseAuthService: FirebaseAuthServiceProtocol {
    var refreshToken: String? {
        get { keychainStorage.value(forKey: tokenKeychainKey) as? String }
        set {
            if let newValue {
                keychainStorage.setValue(newValue, forKey: tokenKeychainKey)
            } else {
                keychainStorage.setValue(nil, forKey: tokenKeychainKey)
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
    
    func authorizeWithGoogleSignInIdToken(in viewController: UIWindow) async throws -> FirebaseTokenData {
        let googleSignInToken = try await googleSigner.signIn(in: viewController)
        let authResponse = try await firebaseSigner.authorizeWithGoogleSignInIdToken(googleSignInToken)
        
        saveAuthResponse(authResponse)
        return authResponse
    }
    
    func authorizeWithTwitterCustomToken(in viewController: UIViewController) async throws -> FirebaseTokenData {
        let customToken = try await twitterSigner.signIn(in: viewController)
        let authResponse = try await firebaseSigner.authorizeWithCustomToken(customToken)
        
        saveAuthResponse(authResponse)
        return authResponse
    }
    
    func authorizeWith(wallet: UDWallet) async throws -> FirebaseTokenData {
        let customToken = try await walletSigner.signInWith(wallet: wallet)
        let authResponse = try await firebaseSigner.authorizeWithCustomToken(customToken)
        
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
