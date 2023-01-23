//
//  OnboardingRecoveryPhrasePresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit
import PromiseKit

final class OnboardingRecoveryPhrasePresenter: BaseRecoveryPhrasePresenter {
    
    private let onboardingFlowManager: OnboardingFlowManager
    private let mode: Mode
    
    override var wallet: UDWallet? { onboardingFlowManager.onboardingData.wallet }
    
    init(view: RecoveryPhraseViewControllerProtocol,
         mode: Mode,
         onboardingFlowManager: OnboardingFlowManager) {
        self.mode = mode
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        if case .iCloud(let _password) = self.mode {
            view?.hideBackButton()
            if let password = _password {
                saveWalletToiCloud(password: password)
            }
        }
        setupForCurrentMode()
        super.viewDidLoad()
    }
    
    override func doneButtonPressed() {
        switch mode {
        case .iCloud:
            onboardingFinished()
        case .manual:
            showConfirmWordsVC()
        }
    }
    
    
    override func saveWalletToiCloud(password: String) {
        super.saveWalletToiCloud(password: password)
        
        onboardingFlowManager.modifyOnboardingData() { $0.backupPassword = nil }
    }
    
}

// MARK: - OnboardingNavigationHandler
extension OnboardingRecoveryPhrasePresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep {
        switch mode {
        case .iCloud:
            return .recoveryPhraseConfirmed
        case .manual:
            return .recoveryPhrase
        }
    }
}

// MARK: - OnboardingDataHandling
extension OnboardingRecoveryPhrasePresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}

// MARK: - Private methods
private extension OnboardingRecoveryPhrasePresenter {
    func setupForCurrentMode() {
        switch mode {
        case .iCloud:
            view?.setDashesProgress(1)
            view?.setDoneButtonTitle(String.Constants.doneButtonTitle.localized())
        case .manual:
            view?.setSubtitleHidden(true)
            view?.setDashesProgress(0.75)
            view?.setDoneButtonTitle(String.Constants.iVeSavedThisWords.localized())
        }
    }
    
    func showConfirmWordsVC() {
        onboardingFlowManager.moveToStep(.confirmWords)
    }
    
    func onboardingFinished() {
        onboardingFlowManager.didFinishOnboarding()
    }
}

// MARK: - Mode
extension OnboardingRecoveryPhrasePresenter {
    enum Mode {
        case iCloud(password: String?), manual
    }
}
