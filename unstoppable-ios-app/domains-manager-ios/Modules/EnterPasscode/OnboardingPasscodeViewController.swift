//
//  OnboardingPasscodeViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.04.2022.
//

import UIKit

final class OnboardingPasscodeViewController: EnterPasscodeViewController {
    
    private var mode: Mode = .create
    private weak var onboardingFlowManager: OnboardingFlowManager?
    override var passwordsNotMatchingErrorMessage: String { String.Constants.passcodeDontMatch.localized() }
    override var progress: Double? {
        if case .newUser(let subFlow) = onboardingFlowManager?.onboardingFlow,
           case .restore = subFlow {
            return 1
        } else {
            return 0.5
        }
    }
    static func instantiate(mode: Mode, onboardingFlowManager: OnboardingFlowManager) -> OnboardingPasscodeViewController {
        let vc = OnboardingPasscodeViewController.nibInstance(nibName: EnterPasscodeViewController.NibName)
        vc.mode = mode
        vc.onboardingFlowManager = onboardingFlowManager
        return vc
    }
    override var analyticsName: Analytics.ViewName {
        switch mode {
        case .create:
            return .createPasscode
        case .confirm:
            return .createPasscodeConfirm
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func didEnter(passcode: [Character]) {
        switch mode {
        case .create:
            logAnalytic(event: .didEnterPasscode)
            Vibration.success.vibrate()
            didCreatePasscode(passcode)
        case .confirm(let passcodeToConfirm):
            logAnalytic(event: .didConfirmPasscode)
            guard passwordsMatch(passcode, passcodeToConfirm) else { return }
            
            didConfirmPasscode(passcode)
        }
    }
    
}

// MARK: - OnboardingDataHandling
extension OnboardingPasscodeViewController: OnboardingDataHandling {
    func willNavigateBack() {
        KeychainPrivateKeyStorage.instance.clear(for: .passcode)
        onboardingFlowManager?.modifyOnboardingData(modifyingBlock: { $0.passcode = nil })
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingPasscodeViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    
    var onboardingStep: OnboardingNavigationController.OnboardingStep {
        switch mode {
        case .create:
            return .createPasscode
        case .confirm:
            return .confirmPasscode
        }
    }
}

// MARK: - Private methods
private extension OnboardingPasscodeViewController {
    func didCreatePasscode(_ passcode: [Character]) {
        onboardingFlowManager?.modifyOnboardingData(modifyingBlock: { $0.passcode = String(passcode) })
        onboardingFlowManager?.moveToStep(.confirmPasscode)
    }
    
    func didConfirmPasscode(_ passcode: [Character]) {
        storePasscode(passcode)
        onboardingFlowManager?.didSetupProtectWallet()
    }
}

// MARK: - Setup methods
private extension OnboardingPasscodeViewController {
    func setup() {
        setupUI()
    }
    
    func setupUI() {
        Task {
            await MainActor.run {
                setDashesProgress(self.progress ?? 0)
            }
        }
        titleLabel.setTitle(mode.title)
    }
}

// MARK: - Mode
extension OnboardingPasscodeViewController {
    enum Mode {
        case create, confirm(passcode: [Character])
        
        var title: String {
            switch self {
            case .create:
                return String.Constants.createPasscode.localized()
            case .confirm:
                return String.Constants.confirmPasscode.localized()
            }
        }
    }
}
