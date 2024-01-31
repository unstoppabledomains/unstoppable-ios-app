//
//  FirebaseAuthenticationServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
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
    var firebaseUser: FirebaseUser? { get }
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

struct FirebaseUser: Codable, Hashable {
    var email: String?
}


