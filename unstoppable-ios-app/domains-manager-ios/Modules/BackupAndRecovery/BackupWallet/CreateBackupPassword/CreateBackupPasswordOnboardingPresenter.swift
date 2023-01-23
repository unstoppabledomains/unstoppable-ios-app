//
//  OnboardingCreatePasswordPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

final class CreateBackupPasswordOnboardingPresenter: CreateBackupPasswordBasePresenter {
    private weak var onboardingFlowManager: OnboardingFlowManager?
    override var walletToBackUp: UDWallet? { onboardingFlowManager?.onboardingData.wallets.first }
    override var progress: Double? { 0.75 }
    override var analyticsName: Analytics.ViewName { .onboardingCreateBackupPassword }

    init(view: CreatePasswordViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager,
         udWalletsService: UDWalletsServiceProtocol) {
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view,
                   udWalletsService: udWalletsService)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            await MainActor.run {
                view?.setDashesProgress(0.75)
            }
        }
    }
    
    override func didSaveWallet(_ wallet: UDWallet, underBackUpPassword password: String) {
        super.didSaveWallet(wallet, underBackUpPassword: password)
        onboardingFlowManager?.modifyOnboardingData() { $0.backupPassword = password }
        
        switch onboardingFlowManager?.onboardingFlow {
        case .newUser, .sameUserWithoutWallets:
            onboardingFlowManager?.moveToStep(.recoveryPhraseConfirmed)
        case .existingUser:
            onboardingFlowManager?.didFinishOnboarding()
        case .none: return
        }
    }
    
    override func failedToBackUpWallet(error: Error) {
        switch onboardingFlowManager?.onboardingFlow {
        case .newUser, .sameUserWithoutWallets:
            super.failedToBackUpWallet(error: error)
        case .existingUser:
            view?.showSimpleAlert(title: String.Constants.saveToICloudFailedTitle.localized(),
                                        body: String.Constants.saveToICloudFailedMessage.localized()) { [weak self] _ in
                self?.onboardingFlowManager?.didFinishOnboarding()
            }
        case .none: return
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension CreateBackupPasswordOnboardingPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .createPassword }
}

// MARK: - OnboardingDataHandling
extension CreateBackupPasswordOnboardingPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}

