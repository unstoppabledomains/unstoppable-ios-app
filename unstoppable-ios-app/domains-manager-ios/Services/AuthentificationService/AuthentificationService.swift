//
//  AuthentificationHelper.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 24.10.2020.
//

import Foundation
import LocalAuthentication
import UIKit

final class AuthentificationService {
    
    private func isPurposeCancellable(_ purpose: AuthenticationPurpose) -> Bool {
        switch purpose {
        case .unlock:
            return false
        case .confirm, .enterOld:
            return true
        }
    }
    
}

// MARK: - AuthentificationServiceProtocol
extension AuthentificationService: AuthentificationServiceProtocol {
    var biometricUIProcessingTime: TimeInterval { biometricType == .touchID ? 0.5 : 1.2 }

    var biometricType: LABiometryType {
        let context = LAContext()
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }
    
    func biometryState() -> BiometryState {
        var error: NSError?
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return .available
        } else if error?.code == LAError.biometryLockout.rawValue {
            return .lockedOut
        }
        return .notAvailable
    }
    

    var isSecureAuthSet: Bool {
        User.instance.getSettings().touchIdActivated || KeychainPrivateKeyStorage.retrievePasscode() != nil
    }
        
    func authenticateWithBiometricWith(uiHandler: AuthenticationUIHandler,
                                       completion: @escaping (Bool?) -> Void) {
        authenticateWith(policy: .deviceOwnerAuthenticationWithBiometrics,
                         uiHandler: uiHandler,
                         completion: completion)
    }
    
    func verifyWith(uiHandler: AuthenticationUIHandler,
                    purpose: AuthenticationPurpose = .confirm,
                    completionCallback: @escaping @autoclosure ()->Void,
                    cancellationCallback: EmptyCallback? = nil) {
        if User.instance.getSettings().touchIdActivated {
            authenticateForCurrentBiometryState(uiHandler: uiHandler,
                                                completionCallback: completionCallback(),
                                                cancellationCallback: cancellationCallback)
        } else {
            guard let passcodeString = KeychainPrivateKeyStorage.retrievePasscode() else {
                Debugger.printWarning("No verification methods available, no passcode, access granted")
                completionCallback()
                return
            }
            
            let passcode = [Character](passcodeString)
            let cancellable = isPurposeCancellable(purpose)
            
            Task {
                let passcodeViewController = await AuthentificationPasscodeNavigationController()
                await passcodeViewController.setupWith(passcode: passcode,
                                                       purpose: purpose,
                                                       proceedSequence: completionCallback,
                                                       cancellable: cancellable,
                                                       cancellationCallback: cancellationCallback)
                uiHandler.showPasscodeViewController(passcodeViewController)
            }
        }
    }
    
    @MainActor
    func verifyWith(uiHandler: AuthenticationUIHandler,
                    purpose: AuthenticationPurpose = .confirm) async throws {
        
        try await withSafeCheckedThrowingContinuation { completion in
            self.verifyWith(uiHandler: uiHandler,
                            purpose: purpose,
                            completionCallback: {
                completion(.success(Void()))
            }(), cancellationCallback: {
                completion(.failure(AuthentificationError.cancelled))
            })
        }
    }
    
}

// MARK: - Private methods
private extension AuthentificationService {
    func authenticateForCurrentBiometryState(uiHandler: AuthenticationUIHandler,
                                             completionCallback: @escaping @autoclosure ()->Void,
                                             cancellationCallback: EmptyCallback? = nil) {
        let biometryState = biometryState()
        if let policy = policyFor(biometryState: biometryState) {
            uiHandler.removeSecurityWallViewController()
            authenticateWith(policy: policy,
                             uiHandler: uiHandler) { response in
                guard response == true else {
                    Debugger.printFailure("face not recognized", critical: false)
                    cancellationCallback?()
                    return
                }
                completionCallback()
            }
        } else {
            Task {
                let securityWall = await SecurityWallViewController.instantiate()
                uiHandler.showSecurityWallViewController(securityWall)
            }
        }
    }
    
    func authenticateWithPasscodeWith(uiHandler: AuthenticationUIHandler,
                                      completion: @escaping (Bool?) -> Void) {
        authenticateWith(policy: .deviceOwnerAuthentication,
                         uiHandler: uiHandler,
                         completion: completion)
    }
    
    func authenticateWith(policy: LAPolicy,
                          uiHandler: AuthenticationUIHandler,
                          completion: @escaping (Bool?) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = String.Constants.cancel.localized()
        context.localizedFallbackTitle = ""
        var error: NSError?
        
        if context.canEvaluatePolicy(policy, error: &error) {
            let reason = reason(for: policy)
            
            context.evaluatePolicy(policy, localizedReason: reason) {
                success, authenticationError in
                
                completion(success)
            }
        } else {
            completion(nil)
        }
    }
    
    func reason(for policy: LAPolicy) -> String {
        switch policy {
        case .deviceOwnerAuthenticationWithBiometrics:
            return String.Constants.identifyYourself.localized(biometricsName ?? "")
        case .deviceOwnerAuthentication:
            return String.Constants.unlockWithPasscode.localized()
        case .deviceOwnerAuthenticationWithWatch:
            return ""
        case .deviceOwnerAuthenticationWithBiometricsOrWatch:
            return ""
        case .deviceOwnerAuthenticationWithWristDetection:
            return ""
        @unknown default:
            return ""
        }
    }
    
    func policyFor(biometryState: BiometryState) -> LAPolicy? {
        switch biometryState {
        case .notAvailable:
            return nil
        case .available:
            return .deviceOwnerAuthenticationWithBiometrics
        case .lockedOut:
            return .deviceOwnerAuthentication
        }
    }
}

// MARK: - BiometryState
extension AuthentificationService {
    enum BiometryState {
        case notAvailable, available, lockedOut
    }
}

private final class AuthentificationPasscodeNavigationController: CNavigationController {
    
    private var cancellationCallback: EmptyCallback?
    
    /// This function sets up appearance and stack of view controllers to be displayed for passcode verification
    /// - Parameters:
    ///   - passcode: Expected passcode
    ///   - proceedSequence: Completion block when correct passcode entered
    ///   - cancellable: Indicates whether this screen can be dismissed manually or passcode entry is required
    func setupWith(passcode: [Character],
                   purpose: AuthenticationPurpose,
                   proceedSequence: @escaping ()->Void,
                   cancellable: Bool,
                   cancellationCallback: EmptyCallback?) {
        loadViewIfNeeded()
        self.cancellationCallback = cancellationCallback
        
        let passcodeVC = VerifyPasscodeViewController.instantiate(passcode: passcode,
                                                                  purpose: purpose,
                                                                  successCompletion: proceedSequence)
        
        if cancellable {
            // To simulate navigation UI we create mock view controller that exist in viewControllers stack before PasscodeVC.
            let inBetweenVC = BaseViewController()
            inBetweenVC.loadViewIfNeeded()
            viewControllers = [inBetweenVC, passcodeVC]
            modalTransitionStyle = .coverVertical
        } else {
            // If it is not cancellable, PasscodeVC will be the only vc in the stack and there won't be a back button
            viewControllers = [passcodeVC]
            modalTransitionStyle = .crossDissolve
        }
        
        modalPresentationStyle = .fullScreen
        isModalInPresentation = true
    }
    
    /// Override popViewController function to track when user press back button
    override func popViewController(animated: Bool, completion: (()->())? = nil) -> UIViewController? {
        dismiss(animated: true, completion: cancellationCallback)
        return nil
    }

}
