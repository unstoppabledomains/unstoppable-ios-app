//
//  OnboardingConfirmWordsPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

final class OnboardingConfirmWordsPresenter: BaseConfirmRecoveryWordsPresenter {
    
    private let onboardingFlowManager: OnboardingFlowManager
    override var wallet: UDWallet? { onboardingFlowManager.onboardingData.wallet }
    
    init(view: ConfirmWordsViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view)
    }
    
    override func didConfirmWords() {
        onboardingFlowManager.didFinishOnboarding()
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingConfirmWordsPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .confirmWords }
}

// MARK: - OnboardingDataHandling
extension OnboardingConfirmWordsPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}
