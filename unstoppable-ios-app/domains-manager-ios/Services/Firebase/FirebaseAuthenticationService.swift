//
//  FirebaseInteractionService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.03.2023.
//

import UIKit

final class FirebaseAuthenticationService: BaseFirebaseInteractionService {

    @UserDefaultsCodableValue(key: .firebaseUser) private var storedFirebaseUser: FirebaseUser?
    private var loadFirebaseUserTask: Task<FirebaseUser, Error>?
    @Published var firebaseUser: FirebaseUser?
    var authorizedUserPublisher: Published<FirebaseUser?>.Publisher { $firebaseUser }

    override init(firebaseAuthService: FirebaseAuthService,
                  firebaseSigner: UDFirebaseSigner) {
        super.init(firebaseAuthService: firebaseAuthService,
                   firebaseSigner: firebaseSigner)
        self.firebaseUser = storedFirebaseUser
        refreshSessionIfNeeded()
        firebaseAuthService.logoutCallback = { [weak self] in
            self?.clearData()
        }
    }
}

// MARK: - FirebaseInteractionServiceProtocol
extension FirebaseAuthenticationService: FirebaseAuthenticationServiceProtocol {
    func authorizeWith(email: String, password: String) async throws {
        try await firebaseAuthService.authorizeWith(email: email, password: password)
        try await userAuthorized()
    }
    
    @MainActor
    func authorizeWithGoogle(in viewController: UIWindow) async throws {
        try await firebaseAuthService.authorizeWithGoogleSignInIdToken(in: viewController)
        try await userAuthorized()
    }
    
    @MainActor
    func authorizeWithTwitter(in viewController: UIViewController) async throws {
        try await firebaseAuthService.authorizeWithTwitterCustomToken(in: viewController)
        try await userAuthorized()
    }
    
    func authorizeWith(wallet: UDWallet) async throws {
        try await firebaseAuthService.authorizeWith(wallet: wallet)
        try await userAuthorized()
    }
    
    func logOut() {
        Task {
            await super.logout()
        }
        clearData()
    }
}

// MARK: - Private methods
private extension FirebaseAuthenticationService {
    func refreshSessionIfNeeded() {
        if firebaseUser != nil {
            Task {
                do {
                    try await fetchUserProfile()
                } catch {
                    self.logOut()
                }
            }
        }
    }
    
    @discardableResult
    func fetchUserProfile() async throws -> FirebaseUser {
        if let loadFirebaseUserTask {
            return try await loadFirebaseUserTask.value
        }
        
        let loadFirebaseUserTask = Task<FirebaseUser, Error> {
            let idToken = try await getIdToken()
            let firebaseUser = try await firebaseSigner.getUserProfile(idToken: idToken)
            return firebaseUser
        }
        
        self.loadFirebaseUserTask = loadFirebaseUserTask
        do {
            let firebaseUser = try await loadFirebaseUserTask.value
            setFirebaseUser(firebaseUser)
            self.loadFirebaseUserTask = nil
            return firebaseUser
        } catch {
            self.loadFirebaseUserTask = nil
            throw error
        }
    }
    
    func setFirebaseUser(_ firebaseUser: FirebaseUser?) {
        let shouldNotifyListeners = firebaseUser != self.firebaseUser
        self.firebaseUser = firebaseUser
        self.storedFirebaseUser = firebaseUser
    }
    
    func userAuthorized() async throws {
        try await fetchUserProfile()
    }
    
    func clearData() {
        setFirebaseUser(nil)
    }
}

// MARK: - Private methods
private extension FirebaseAuthenticationService {
  
}

struct FirebaseTokenData: Codable {
    let idToken: String
    let expiresIn: String
    var expirationDate: Date?
    let refreshToken: String
}

