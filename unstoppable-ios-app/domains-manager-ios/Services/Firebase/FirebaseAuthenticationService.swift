//
//  FirebaseInteractionService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.03.2023.
//

import UIKit

protocol FirebaseAuthenticationServiceListener: AnyObject {
    func firebaseUserUpdated(firebaseUser: FirebaseUser?)
}

final class FirebaseAuthenticationServiceListenerHolder: Equatable {
    
    weak var listener: FirebaseAuthenticationServiceListener?
    
    init(listener: FirebaseAuthenticationServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: FirebaseAuthenticationServiceListenerHolder, rhs: FirebaseAuthenticationServiceListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
}

protocol FirebaseAuthenticationServiceProtocol: ObservableObject {
    var isAuthorized: Bool { get }
    var isAuthorizedPublisher: Published<Bool>.Publisher  { get }
    
    func authorizeWith(email: String, password: String) async throws
    @MainActor func authorizeWithGoogle(in viewController: UIWindow) async throws
    @MainActor func authorizeWithTwitter(in viewController: UIViewController) async throws
    func authorizeWith(wallet: UDWallet) async throws
    func getUserProfile() async throws -> FirebaseUser
    
    func logout()
    // Listeners
    func addListener(_ listener: FirebaseAuthenticationServiceListener)
    func removeListener(_ listener: FirebaseAuthenticationServiceListener)
}

final class FirebaseAuthenticationService: BaseFirebaseInteractionService {

    private var firebaseUser: FirebaseUser?
    private var listenerHolders: [FirebaseAuthenticationServiceListenerHolder] = []
    private var loadFirebaseUserTask: Task<FirebaseUser, Error>?
    @Published var isAuthorized: Bool
    var isAuthorizedPublisher: Published<Bool>.Publisher { $isAuthorized }

    override init(firebaseAuthService: FirebaseAuthService,
                  firebaseSigner: UDFirebaseSigner) {
        self.isAuthorized = firebaseAuthService.isAuthorised
        super.init(firebaseAuthService: firebaseAuthService,
                   firebaseSigner: firebaseSigner)
        refreshUserProfileAsync()
    }
    
    override func logout() {
        super.logout()
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
        } else if let loadFirebaseUserTask {
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
    func setFirebaseUser(_ firebaseUser: FirebaseUser?) {
        let shouldNotifyListeners = firebaseUser != self.firebaseUser
        self.firebaseUser = firebaseUser
        
        if shouldNotifyListeners  {
            listenerHolders.forEach { holder in
                holder.listener?.firebaseUserUpdated(firebaseUser: firebaseUser)
            }
        }
    }
    func refreshUserProfileAsync() {
        Task {
            _ = try? await getUserProfile()
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

struct FirebaseUser: Codable, Hashable {
    var email: String?
}



