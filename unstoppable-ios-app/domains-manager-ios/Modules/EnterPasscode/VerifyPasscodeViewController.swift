//
//  VerifyPasscodeViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.04.2022.
//

import UIKit

final class VerifyPasscodeViewController: EnterPasscodeViewController {
    
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
        guard passwordsMatch(passcode, self.passcode) else { return }
        
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
}

