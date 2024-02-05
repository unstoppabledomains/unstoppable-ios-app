//
//  FirebaseInteractionService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.03.2023.
//

import UIKit

final class FirebaseAuthenticationService: BaseFirebaseInteractionService {

    private(set) var firebaseUser: FirebaseUser?
    private var listenerHolders: [FirebaseAuthenticationServiceListenerHolder] = []
    private var loadFirebaseUserTask: Task<FirebaseUser, Error>?
    @Published var isAuthorized: Bool
    var isAuthorizedPublisher: Published<Bool>.Publisher { $isAuthorized }
    @UserDefaultsCodableValue(key: .firebaseUser) private var storedFirebaseUser: FirebaseUser?

    override init(firebaseAuthService: FirebaseAuthService,
                  firebaseSigner: UDFirebaseSigner) {
        self.isAuthorized = firebaseAuthService.isAuthorised
        super.init(firebaseAuthService: firebaseAuthService,
                   firebaseSigner: firebaseSigner)
        refreshSessionIfNeeded()
    }
    
    func logOut() {
        Task {
            await super.logout()
        }
        setFirebaseUser(nil)
        isAuthorized = false
    }
}

// MARK: - FirebaseInteractionServiceProtocol
extension FirebaseAuthenticationService: FirebaseAuthenticationServiceProtocol {
    func authorizeWith(email: String, password: String) async throws {
        try await firebaseAuthService.authorizeWith(email: email, password: password)
        userAuthorized()
    }
    
    @MainActor
    func authorizeWithGoogle(in viewController: UIWindow) async throws {
        try await firebaseAuthService.authorizeWithGoogleSignInIdToken(in: viewController)
        userAuthorized()
    }
    
    @MainActor
    func authorizeWithTwitter(in viewController: UIViewController) async throws {
        try await firebaseAuthService.authorizeWithTwitterCustomToken(in: viewController)
        userAuthorized()
    }
    
    func authorizeWith(wallet: UDWallet) async throws {
        try await firebaseAuthService.authorizeWith(wallet: wallet)
        userAuthorized()
    }
    
    func getUserProfile() async throws -> FirebaseUser {
        if let firebaseUser {
            return firebaseUser
        } 
        return try await fetchUserProfile()
    }
    
    // Listeners
    func addListener(_ listener: FirebaseAuthenticationServiceListener) {
        if !listenerHolders.contains(where: { $0.listener === listener }) {
            listenerHolders.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: FirebaseAuthenticationServiceListener) {
        listenerHolders.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - Private methods
private extension FirebaseAuthenticationService {
    func refreshSessionIfNeeded() {
        if let storedFirebaseUser {
            firebaseUser = storedFirebaseUser
            isAuthorized = true
            Task {
                do {
                    _ = try await fetchUserProfile()
                } catch {
                    self.logOut()
                }
            }
        }
    }
    
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
        
        if shouldNotifyListeners  {
            listenerHolders.forEach { holder in
                holder.listener?.firebaseUserUpdated(firebaseUser: firebaseUser)
            }
        }
    }
    
    func refreshUserProfileAsync() {
        firebaseUser = storedFirebaseUser
        Task {
            _ = try? await fetchUserProfile()
        }
    }
    
    func userAuthorized() {
        isAuthorized = true
        refreshUserProfileAsync()
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

