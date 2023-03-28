//
//  LoginOnboardingViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import UIKit

final class LoginOnboardingViewPresenter: LoginViewPresenter {
    
    private weak var onboardingFlowManager: OnboardingFlowManager?

    init(view: LoginViewProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        super.init(view: view)
        self.onboardingFlowManager = onboardingFlowManager
    }
    
    override func loginWithEmailAction() {
        onboardingFlowManager?.moveToStep(.loginWithEmailAndPassword)
    }
    
    override func userDidAuthorize() {
        onboardingFlowManager?.moveToStep(.loadingParkedDomains)
    }
}

// MARK: - OnboardingNavigationHandler
extension LoginOnboardingViewPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .loginWithWebsite }
}

// MARK: - OnboardingDataHandling
extension LoginOnboardingViewPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}

