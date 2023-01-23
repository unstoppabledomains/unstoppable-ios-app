//
//  OnboardingWalletConnectedPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

final class OnboardingWalletConnectedPresenter: BaseExternalWalletConnectedPresenter {
    
    private weak var onboardingFlowManager: OnboardingFlowManager?
    override var wallet: UDWallet? { onboardingFlowManager?.onboardingData.wallets.first }
    override var analyticsName: Analytics.ViewName { .onboardingExternalWalletConnected }

    init(view: WalletConnectedViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view)
    }
    
    override func didTapContinueButton() {
        if case .sameUserWithoutWallets = self.onboardingFlowManager?.onboardingFlow {
            self.onboardingFlowManager?.didFinishOnboarding()
        } else {
            self.onboardingFlowManager?.moveToStep(.protectWallet)
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingWalletConnectedPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .externalWalletConnected }
}

// MARK: - OnboardingDataHandling
extension OnboardingWalletConnectedPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}

