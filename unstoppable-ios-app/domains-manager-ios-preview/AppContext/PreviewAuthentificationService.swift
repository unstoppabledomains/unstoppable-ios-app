//
//  PreviewAuthentificationService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation
import LocalAuthentication
import UIKit
final class AuthentificationService {
    
    
}
// MARK: - AuthentificationServiceProtocol
extension AuthentificationService: AuthentificationServiceProtocol {
    var biometricType: LABiometryType {
        .faceID
    }
    
    var biometricIcon: UIImage? {
        .faceIdIcon
    }
    
    var isSecureAuthSet: Bool {
        true
    }
    
    var biometricUIProcessingTime: TimeInterval {
        1
    }
    
    func biometryState() -> BiometryState {
        .available
    }
    
    func authenticateWithBiometricWith(uiHandler: AuthenticationUIHandler, completion: @escaping (Bool?) -> Void) {
        
    }
    
    func verifyWith(uiHandler: AuthenticationUIHandler, purpose: AuthenticationPurpose, completionCallback: @autoclosure @escaping () -> Void, cancellationCallback: (() -> ())?) {
        
    }
    
    func verifyWith(uiHandler: AuthenticationUIHandler, purpose: AuthenticationPurpose) async throws {
        
    }
    
    
}

extension AuthentificationService {
    enum BiometryState {
        case notAvailable, available, lockedOut
    }
}
