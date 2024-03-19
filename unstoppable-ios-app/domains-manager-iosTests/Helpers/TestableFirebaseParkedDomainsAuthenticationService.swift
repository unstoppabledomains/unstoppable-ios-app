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
        
    }
    
    func authorizeWithGoogle(in viewController: UIWindow) async throws {
        
    }
    
    func authorizeWithTwitter(in viewController: UIViewController) async throws {
        
    }
    
    func authorizeWith(wallet: UDWallet) async throws {
        
    }
    
    func logOut() {
        
    }
}


// MARK: - Open methods
extension TestableFirebaseParkedDomainsAuthenticationService {
    func setFirebaseUser() {
        firebaseUser = .init(email: "qq@qq.qq")
    }
}
