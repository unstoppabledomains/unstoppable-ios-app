//
//  OnboardingCreatePasswordPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit
import PromiseKit

final class OnboardingCreatePasswordPresenter: BaseCreateBackupPasswordPresenterProtocol {
    private let onboardingFlowManager: OnboardingFlowManager
    
    init(view: CreatePasswordViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view)
    }
    
    override func createPasswordButtonPressed() {
        guard let view = self.view else { return }
        
        let password = view.password
        onboardingFlowManager.modifyOnboardingData() { $0.backupPassword = password }
        
        switch onboardingFlowManager.onboardingFlow {
        case .newUser:
            onboardingFlowManager.moveToStep(.recoveryPhraseConfirmed)
        case .existingUser:
            let wallets = UDWalletsStorage.instance
                .getWalletsList(ownedBy: User.defaultId)
                .filter{$0.walletState == .verified}
            let success = iCloudWalletStorage.saveToiCloud(wallets: wallets,
                                                           password: password)
            
            if !success {
                DispatchQueue.main.async { [weak self] in
                    self?.view?.showSimpleAlert(title: String.Constants.saveToICloudFailedTitle.localized(),
                                                body: String.Constants.saveToICloudFailedMessage.localized()) {_ in
                        self?.onboardingFlowManager.didFinishOnboarding()
                    }
                }
            } else {
                onboardingFlowManager.didFinishOnboarding()
            }
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingCreatePasswordPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .createPassword }
}

// MARK: - OnboardingDataHandling
extension OnboardingCreatePasswordPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}

