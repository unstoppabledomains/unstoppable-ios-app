//
//  NoParkedDomainsFoundOnboardingViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import Foundation

class NoParkedDomainsFoundOnboardingViewPresenter: NoParkedDomainsFoundViewPresenter {

    private weak var onboardingFlowManager: OnboardingFlowManager?

    init(view: NoParkedDomainsFoundViewProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        super.init(view: view)
        self.onboardingFlowManager = onboardingFlowManager
    }
    
    override func confirmButtonPressed() {
        Task {
            
        }
    }
}
