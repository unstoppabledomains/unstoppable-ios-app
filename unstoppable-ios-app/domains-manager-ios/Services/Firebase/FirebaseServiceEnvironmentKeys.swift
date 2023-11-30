//
//  FirebaseServiceEnvironmentKeys.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import Foundation
import SwiftUI

private struct FirebaseAuthenticationServiceKey: EnvironmentKey {
    static let defaultValue = appContext.firebaseParkedDomainsAuthenticationService
}

extension EnvironmentValues {
    var firebaseAuthenticationService: any FirebaseAuthenticationServiceProtocol {
        get { self[FirebaseAuthenticationServiceKey.self] }
        set { self[FirebaseAuthenticationServiceKey.self] = newValue }
    }
}
