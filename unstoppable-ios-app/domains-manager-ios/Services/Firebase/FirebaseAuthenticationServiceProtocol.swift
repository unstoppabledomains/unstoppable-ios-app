//
//  FirebaseAuthenticationServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

protocol FirebaseAuthenticationServiceProtocol: ObservableObject {
    var firebaseUser: FirebaseUser? { get }
    var authorizedUserPublisher: Published<FirebaseUser?>.Publisher  { get }
    
    func authorizeWith(email: String, password: String) async throws
    @MainActor func authorizeWithGoogle(in viewController: UIWindow) async throws
    @MainActor func authorizeWithTwitter(in viewController: UIViewController) async throws
    func authorizeWith(wallet: UDWallet) async throws
    
    func logOut()
}

struct FirebaseUser: Codable, Hashable {
    var email: String?
    
    var displayName: String { email ?? "-||-" }
}


