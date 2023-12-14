//
//  NoParkedDomainsFoundOnboardingViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import UIKit

final class NoParkedDomainsFoundOnboardingViewPresenter: NoParkedDomainsFoundViewPresenter {

    private weak var onboardingFlowManager: OnboardingFlowManager?

    init(view: NoParkedDomainsFoundViewProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        super.init(view: view)
        self.onboardingFlowManager = onboardingFlowManager
    }
    
    override func confirmButtonPressed() {
        appContext.firebaseParkedDomainsAuthenticationService.logout()
        view?.cNavigationController?.popTo(RestoreWalletViewController.self)
    }
}

// MARK: - OnboardingNavigationHandler
extension NoParkedDomainsFoundOnboardingViewPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .noParkedDomains }
}

// MARK: - OnboardingDataHandling
extension NoParkedDomainsFoundOnboardingViewPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}

