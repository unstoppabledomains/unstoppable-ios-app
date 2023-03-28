//
//  LoginWithEmailOnboardingViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import Foundation

final class LoginWithEmailOnboardingViewPresenter: LoginWithEmailViewPresenter {
    
    private weak var onboardingFlowManager: OnboardingFlowManager?
  
    override var progress: Double? { 0.5 }
    
    init(view: LoginWithEmailViewProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        super.init(view: view)
        self.onboardingFlowManager = onboardingFlowManager
    }
    
    override func didAuthorizeAction() {
        onboardingFlowManager?.moveToStep(.loadingParkedDomains)
    }
}
