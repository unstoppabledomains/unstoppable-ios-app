//
//  FirebaseAuthError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2023.
//

import Foundation

enum FirebaseAuthError: Error {
    case unexpectedResponse
    case failedToBuildURL
    case failedToGetCodeFromCallbackURL
    case userCancelled
}
