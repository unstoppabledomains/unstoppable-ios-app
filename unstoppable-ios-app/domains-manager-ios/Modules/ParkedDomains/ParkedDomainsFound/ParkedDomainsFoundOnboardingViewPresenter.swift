//
//  ParkedDomainsFoundOnboardingViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import UIKit

final class ParkedDomainsFoundOnboardingViewPresenter: ParkedDomainsFoundViewPresenter {
    
    private weak var onboardingFlowManager: OnboardingFlowManager?
    
    override var title: String {
        String.Constants.pluralWeFoundNDomains.localized(domains.count)
    }
    override var progress: Double? { 1 }
    
    init(view: ParkedDomainsFoundViewProtocol,
         domains: [FirebaseDomainDisplayInfo],
         onboardingFlowManager: OnboardingFlowManager) {
        super.init(view: view, domains: domains)
        self.onboardingFlowManager = onboardingFlowManager
    }
    
    override func importButtonPressed() {
        if case .sameUserWithoutWallets = self.onboardingFlowManager?.onboardingFlow {
            onboardingFlowManager?.didFinishOnboarding()
        } else {
            onboardingFlowManager?.moveToStep(.protectWallet)
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension ParkedDomainsFoundOnboardingViewPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .parkedDomainsFound }
}

// MARK: - OnboardingDataHandling
extension ParkedDomainsFoundOnboardingViewPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}

