//
//  FirebaseAuthError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2023.
//

import Foundation

enum FirebaseAuthError: String, LocalizedError {
    case unexpectedResponse
    case refreshTokenExpired
    case failedToBuildURL
    case failedToGetCodeFromCallbackURL
    case userCancelled
    
    case failedToFetchFirebaseUserProfile
    
    case failedToGetTokenExpiresData
    case firebaseUserNotAuthorisedInTheApp
    
    public var errorDescription: String? { rawValue }

}
