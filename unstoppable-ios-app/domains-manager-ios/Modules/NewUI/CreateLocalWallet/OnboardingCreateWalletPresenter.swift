//
//  CreateWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

final class OnboardingCreateWalletPresenter: BaseCreateWalletPresenter {
    private let onboardingFlowManager: OnboardingFlowManager
    private var wallet: UDWallet?
    
    init(view: CreateWalletViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view)
    }
    
    override func walletCreated(_ wallet: UDWallet) {
        onboardingFlowManager.modifyOnboardingData() { $0.wallet = wallet }
        self.onboardingFlowManager.moveToStep(.protectWallet)
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingCreateWalletPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .createWallet }
}

// MARK: - OnboardingDataHandling
extension OnboardingCreateWalletPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}
