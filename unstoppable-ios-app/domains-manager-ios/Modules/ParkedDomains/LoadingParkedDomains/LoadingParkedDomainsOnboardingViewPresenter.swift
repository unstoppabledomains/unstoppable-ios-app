//
//  LoadingParkedDomainsOnboardingViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import UIKit

final class LoadingParkedDomainsOnboardingViewPresenter: LoadingParkedDomainsViewPresenter {

    private weak var onboardingFlowManager: OnboardingFlowManager?
    private let loginProvider: LoginProvider

    init(view: LoadingParkedDomainsViewProtocol,
         loginProvider: LoginProvider,
         onboardingFlowManager: OnboardingFlowManager) {
        self.loginProvider = loginProvider
        super.init(view: view)
        self.onboardingFlowManager = onboardingFlowManager
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        guard onboardingFlowManager?.onboardingData.parkedDomains == nil else { return } // Restoring steps
        
        Task {
            do {
                switch loginProvider {
                case .email, .google, .twitter:
                    let parkedDomains = try await appContext.firebaseParkedDomainsService.getParkedDomains()
                    let displayInfo = parkedDomains.map({ FirebaseDomainDisplayInfo(firebaseDomain: $0) })
                    
                    await MainActor.run {
                        if parkedDomains.isEmpty {
                            onboardingFlowManager?.moveToStep(.noParkedDomains)
                        } else {
                            onboardingFlowManager?.modifyOnboardingData { onboardingData in
                                onboardingData.parkedDomains = displayInfo
                            }
                            onboardingFlowManager?.moveToStep(.parkedDomainsFound)
                        }
                    }
                case .apple:
                    try? await Task.sleep(seconds: 1.5)
                    onboardingFlowManager?.moveToStep(.noParkedDomains)
                }
            } catch {
                view?.showAlertWith(error: error, handler: { [weak self] _ in
                    self?.failedToLoadParkedDomains()
                })
            }
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension LoadingParkedDomainsOnboardingViewPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .loadingParkedDomains }
}

// MARK: - OnboardingDataHandling
extension LoadingParkedDomainsOnboardingViewPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}

// MARK: - Private methods
private extension LoadingParkedDomainsOnboardingViewPresenter {
    func failedToLoadParkedDomains() {
        Task { @MainActor in
            appContext.firebaseParkedDomainsAuthenticationService.logout()
            view?.cNavigationController?.popTo(LoginViewController.self)
        }
    }
}
