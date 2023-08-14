//
//  AuthentificationServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.08.2022.
//

import UIKit
import LocalAuthentication

protocol AuthentificationServiceProtocol {
    var biometricType: LABiometryType { get }
    var biometricsName: String? { get }
    var isSecureAuthSet: Bool { get }
    var biometricUIProcessingTime: TimeInterval { get }
    
    func biometryState() -> AuthentificationService.BiometryState
    func authenticateWithBiometricWith(uiHandler: AuthenticationUIHandler,
                                       completion: @escaping (Bool?) -> Void)
    func verifyWith(uiHandler: AuthenticationUIHandler,
                    purpose: AuthenticationPurpose,
                    completionCallback: @escaping @autoclosure ()->Void,
                    cancellationCallback: (()->())?)
    @MainActor
    func verifyWith(uiHandler: AuthenticationUIHandler,
                    purpose: AuthenticationPurpose) async throws
}

protocol AuthenticationUIHandler {
    func showPasscodeViewController(_ passcodeViewController: UIViewController)
    func showSecurityWallViewController(_ securityWallViewController: UIViewController)
    func removeSecurityWallViewController()
}

extension AuthentificationServiceProtocol {
    var biometricsName: String? {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default: return nil
        }
    }
}

enum AuthenticationPurpose {
    case unlock
    case confirm
    case enterOld
}

enum AuthentificationError: Error {
    case cancelled
}
