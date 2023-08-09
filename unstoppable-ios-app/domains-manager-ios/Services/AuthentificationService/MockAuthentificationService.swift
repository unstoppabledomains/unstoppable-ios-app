//
//  MockAuthentificationService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.08.2022.
//

import Foundation
import LocalAuthentication

final class MockAuthentificationService {

    var biometricTypeToUse: LABiometryType = .faceID
    var isBiometricEnabled = true
    var shouldUseBiometricAuth = true
    var shouldFailAuth = false
    
    init() {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        isBiometricEnabled = (environment[TestsEnvironment.isBiometricEnabled.rawValue] ?? "1") == "1" // Enabled default
        shouldUseBiometricAuth = (environment[TestsEnvironment.shouldUseBiometricAuth.rawValue] ?? "1") == "1" // Use by default
        shouldFailAuth = (environment[TestsEnvironment.shouldFailAuth.rawValue] ?? "0") == "1" // Not fail by default
        #endif
    }
    
}

// MARK: - AuthentificationServiceProtocol
extension MockAuthentificationService: AuthentificationServiceProtocol {
    var biometricUIProcessingTime: TimeInterval {
        0.1
    }
    
    var biometricType: LABiometryType {
        biometricTypeToUse
    }
    
    func biometryState() -> AuthentificationService.BiometryState {
        isBiometricEnabled ? .available : .notAvailable
    }
    
    var isSecureAuthSet: Bool { !shouldFailAuth }
    
    func authenticateWithBiometricWith(uiHandler: AuthenticationUIHandler, completion: @escaping (Bool?) -> Void) {
        guard isBiometricEnabled else {
            completion(false)
            return
        }
        completion(!shouldFailAuth)
    }
    
    func verifyWith(uiHandler: AuthenticationUIHandler,
                    purpose: AuthenticationPurpose,
                    completionCallback: @autoclosure @escaping () -> Void,
                    cancellationCallback: (()->())?) {
        if shouldUseBiometricAuth {
            if biometryState() == .available {
                if purpose == .unlock {
                    completionCallback()
                    return 
                }
                uiHandler.removeSecurityWallViewController()
                authenticateWithBiometricWith(uiHandler: uiHandler) { response in
                    guard let response = response else {
                        completionCallback()
                        return
                    }
                    guard response else {
                        cancellationCallback?()
                        return
                    }
                    completionCallback()
                }
            } else {
//                let securityWall = SecurityWallViewController.instantiate()
//                uiHandler.showSecurityWallViewController(securityWall)
            }
        } else {
            if shouldFailAuth {
                cancellationCallback?()
            } else {
                completionCallback()
            }
        }
    }
    
    func verifyWith(uiHandler: AuthenticationUIHandler, purpose: AuthenticationPurpose) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.verifyWith(uiHandler: uiHandler,
                            purpose: purpose,
                            completionCallback: {
                continuation.resume()
            }(), cancellationCallback: {
                continuation.resume(throwing: AuthentificationError.cancelled)
            })
        }
    }
    
}
