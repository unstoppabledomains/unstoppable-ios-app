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
            
    private let refreshTokenStorage: FirebaseAuthRefreshTokenStorageProtocol
    private let twitterSigner = UDTwitterSigner()
    private let googleSigner = UDGoogleSigner()
    private let walletSigner = UDWalletSigner()
    private let firebaseSigner: UDFirebaseSigner

    private var tokenData: FirebaseTokenData?

    init(firebaseSigner: UDFirebaseSigner,
         refreshTokenStorage: FirebaseAuthRefreshTokenStorageProtocol) {
        self.firebaseSigner = firebaseSigner
        self.refreshTokenStorage = refreshTokenStorage
    }
}

// MARK: - FirebaseAuthServiceProtocol
extension FirebaseAuthService: FirebaseAuthServiceProtocol {
    var refreshToken: String? {
        get { refreshTokenStorage.getAuthRefreshToken() }
        set {
            if let newValue {
                refreshTokenStorage.setAuthRefreshToken(newValue)
            } else {
                refreshTokenStorage.clearAuthRefreshToken()
            }
        }
    }
    var isAuthorised: Bool { refreshToken != nil }
    var firebaseProfile: String { "" }
  
    func authorizeWith(email: String, password: String) async throws {
        let authResponse = try await firebaseSigner.authorizeWith(email: email, password: password)
        
        saveAuthResponse(authResponse)
    }
    
    func authorizeWithGoogleSignInIdToken(in viewController: UIWindow) async throws {
        let googleSignInToken = try await googleSigner.signIn(in: viewController)
        let authResponse = try await firebaseSigner.authorizeWithGoogleSignInIdToken(googleSignInToken)
        
        saveAuthResponse(authResponse)
    }
    
    func authorizeWithTwitterCustomToken(in viewController: UIViewController) async throws {
        let customToken = try await twitterSigner.signIn(in: viewController)
        let authResponse = try await firebaseSigner.authorizeWithCustomToken(customToken)
        
        saveAuthResponse(authResponse)
    }
    
    func authorizeWith(wallet: UDWallet) async throws {
        let customToken = try await walletSigner.signInWith(wallet: wallet)
        let authResponse = try await firebaseSigner.authorizeWithCustomToken(customToken)
        
        saveAuthResponse(authResponse)
    }
    
    func logout() {
        refreshToken = nil 
        tokenData = nil
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
}

// MARK: - Private methods
private extension FirebaseAuthService {
    func saveAuthResponse(_ authResponse: FirebaseTokenData) {
        refreshToken = authResponse.refreshToken
        tokenData = authResponse
    }
    
    func refreshIdTokenIfPossible() async throws {
        if let refreshToken = refreshToken {
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
            let tokenData = FirebaseTokenData(idToken: authResponse.idToken,
                                              expiresIn: authResponse.expiresIn,
                                              expirationDate: expirationDate,
                                              refreshToken: authResponse.refreshToken)
            saveAuthResponse(tokenData)
        } catch FirebaseAuthError.refreshTokenExpired {
            logout()
            throw FirebaseAuthError.refreshTokenExpired
        } catch {
            throw error
        }
    }
}
