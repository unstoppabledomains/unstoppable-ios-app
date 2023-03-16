//
//  FirebaseAuthService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2023.
//

import UIKit

protocol FirebaseAuthServiceProtocol {
    
}

final class FirebaseAuthService {
    
}

// MARK: - FirebaseAuthServiceProtocol
extension FirebaseAuthService: FirebaseAuthServiceProtocol {
    var refreshToken: String { "" }
    var firebaseProfile: String { "" }
    
    func authorizeWith(email: String, password: String) async throws {
      
    }
    
    func authorizeWithGoogleSignInIdToken(in viewController: UIViewController) async throws {
      
    }
    
    func authorizeWithTwitterCustomToken(in viewController: UIViewController) async throws {
   
    }
    
    func refreshIDTokenWith(refreshToken: String) async throws {
        
    }
}
