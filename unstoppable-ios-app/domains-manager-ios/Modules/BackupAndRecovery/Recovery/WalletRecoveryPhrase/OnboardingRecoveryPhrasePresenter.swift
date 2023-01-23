//
//  OnboardingRecoveryPhrasePresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

final class OnboardingRecoveryPhrasePresenter: BaseRecoveryPhrasePresenter {
    
    private weak var onboardingFlowManager: OnboardingFlowManager?
    private let mode: Mode
    
    override var wallet: UDWallet? { onboardingFlowManager?.onboardingData.wallets.first }
    override var analyticsName: Analytics.ViewName { .onboardingRecoveryPhrase }
    override var progress: Double? {
        switch mode {
        case .iCloud:
            return 1
        case .manual:
            return 0.75
        }
    }
    
    init(view: RecoveryPhraseViewControllerProtocol,
         recoveryType: UDWallet.RecoveryType,
         mode: Mode,
         onboardingFlowManager: OnboardingFlowManager) {
        self.mode = mode
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view, recoveryType: recoveryType)
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
        Task {
            await MainActor.run {
                view?.setDashesProgress(self.progress)
            }
        }
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
        onboardingFlowManager?.modifyOnboardingData() { $0.backupPassword = nil }
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
            view?.setDoneButtonTitle(String.Constants.doneButtonTitle.localized())
        case .manual:
            view?.setSubtitleHidden(true)
            view?.setDoneButtonTitle(String.Constants.iVeSavedThisWords.localized())
        }
    }
    
    func showConfirmWordsVC() {
        onboardingFlowManager?.moveToStep(.confirmWords)
    }
    
    func onboardingFinished() {
        onboardingFlowManager?.didFinishOnboarding()
    }
}

// MARK: - Mode
extension OnboardingRecoveryPhrasePresenter {
    enum Mode {
        case iCloud(password: String?), manual
    }
}
