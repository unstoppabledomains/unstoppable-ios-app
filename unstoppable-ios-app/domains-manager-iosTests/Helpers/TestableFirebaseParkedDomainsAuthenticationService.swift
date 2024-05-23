//
//  TestableFirebaseParkedDomainsAuthenticationService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 19.03.2024.
//

import UIKit
@testable import domains_manager_ios
import Combine

final class TestableFirebaseParkedDomainsAuthenticationService: FirebaseAuthenticationServiceProtocol, FailableService {
    
    var shouldFail: Bool = false
    
    @Published var firebaseUser: FirebaseUser?
    var authorizedUserPublisher: Published<FirebaseUser?>.Publisher { $firebaseUser }
    
    func authorizeWith(email: String, password: String) async throws {
        try failIfNeeded()
        setFirebaseUser()
    }
    
    func authorizeWithGoogle(in viewController: UIWindow) async throws {
        try failIfNeeded()
        setFirebaseUser()
    }
    
    func authorizeWithTwitter(in viewController: UIViewController) async throws {
        try failIfNeeded()
        setFirebaseUser()
    }
    
    func authorizeWith(wallet: UDWallet) async throws {
        try failIfNeeded()
        setFirebaseUser()
    }
    
    func logOut() {
        
    }
}


// MARK: - Open methods
extension TestableFirebaseParkedDomainsAuthenticationService {
    func simulateAuthorise() {
        setFirebaseUser()
    }
    
    func simulateDeauthorise() {
        firebaseUser = nil 
    }
    
    func mockFirebaseUser() -> FirebaseUser {
        FirebaseUser(email: "qq@qq.qq")
    }
    
    func setFirebaseUser() {
        firebaseUser = mockFirebaseUser()
    }
}
