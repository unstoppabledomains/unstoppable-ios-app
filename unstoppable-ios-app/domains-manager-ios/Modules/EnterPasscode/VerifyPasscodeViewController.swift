//
//  VerifyPasscodeViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.04.2022.
//

import UIKit

final class VerifyPasscodeViewController: EnterPasscodeViewController {
    
    static let passwordAttemptsKey = "CURRENT_PASSWORD_ATTEMPTS_COUNT"
    static let waitThreshold = 3
    static let wipeThreshold = 12
    
    private var passcode: [Character] = []
    private var purpose: AuthenticationPurpose = .unlock
    private var successCompletion: EmptyCallback?
    override var passwordsNotMatchingErrorMessage: String { String.Constants.incorrectPasscode.localized() }
    override var analyticsName: Analytics.ViewName { .enterPasscodeVerification }
    
    static func instantiate(passcode: [Character],
                            purpose: AuthenticationPurpose,
                            successCompletion: @escaping EmptyCallback) -> VerifyPasscodeViewController {
        let vc = VerifyPasscodeViewController.nibInstance(nibName: EnterPasscodeViewController.NibName)
        vc.passcode = passcode
        vc.purpose = purpose
        vc.successCompletion = successCompletion
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func didEnter(passcode: [Character]) {
        guard passwordsMatch(passcode, self.passcode) else {
            let shouldLeave = handlePasswordMismatch()
            if shouldLeave {
                resetFailedAttempts()
                leaveThisController()
            }
            self.reset()
            return
        }
        
        resetFailedAttempts()
        leaveThisController()
    }
    
    override func getWarningType() -> DigitalKeyboardViewController.WarningType {
        let count = getFailedAttempts()
        if count >= Self.wipeThreshold - 1 {
            return .wipe
        }
        if count > 0 && count % Self.waitThreshold == 0 {
            return .lock
        }
        return .none
    }
    
    func leaveThisController() {
        if navigationController?.viewControllers.count == 1 {
            self.dismiss(animated: true)
            successCompletion?()
        } else {
            self.dismiss(animated: true, completion: successCompletion)
        }
    }
}

// MARK: - Setup methods
private extension VerifyPasscodeViewController {
    func setup() {
        setupUI()
    }
    
    func setupUI() {
        dashesProgressView.isHidden = true
        titleLabel.setTitle(titleForPurpose())
    }
    
    func titleForPurpose() -> String {
        switch purpose {
        case .unlock:
            return String.Constants.unlockWithPasscode.localized()
        case .confirm:
            return String.Constants.confirmYourPasscode.localized()
        case .enterOld:
            return String.Constants.enterOldPasscode.localized()
        }
    }
    
    func handlePasswordMismatch() -> Bool {
        let newCount = incrementFailedAttempts()
        if newCount >= Self.wipeThreshold {
            // wipe all cache
            appContext.udWalletsService.removeAllWallets()
            Storage.instance.cleanAllCache()
            return true // return true if should leave the Password screen
        }
        return false
    }
}

// MARK: - Persistant counter methods
private extension VerifyPasscodeViewController {
    func getFailedAttempts() -> Int {
        return (UserDefaults.standard.object(forKey: Self.passwordAttemptsKey) as? Int) ?? 0
    }
    
    func incrementFailedAttempts() -> Int {
        let newCount = getFailedAttempts() + 1
        UserDefaults.standard.set(newCount, forKey: Self.passwordAttemptsKey)
        return newCount
    }
    
    func resetFailedAttempts() {
        UserDefaults.standard.set(Int.init(integerLiteral: 0), forKey: Self.passwordAttemptsKey)
    }
}

