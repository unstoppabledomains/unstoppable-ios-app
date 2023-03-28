//
//  LoadingParkedDomainsOnboardingViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import Foundation

final class LoadingParkedDomainsOnboardingViewPresenter: LoadingParkedDomainsViewPresenter {

    private weak var onboardingFlowManager: OnboardingFlowManager?

    init(view: LoadingParkedDomainsViewProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        super.init(view: view)
        self.onboardingFlowManager = onboardingFlowManager
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        Task {
            do {
                let parkedDomains = try await appContext.firebaseDomainsService.loadParkedDomains()
                let displayInfo = parkedDomains.map({ FirebaseDomainDisplayInfo(firebaseDomain: $0) })
                
                await MainActor.run {
//                    if parkedDomains.isEmpty {
//                        moveToStep(.noParkedDomains)
//                    } else {
//                        moveToStep(.parkedDomainsFound(parkedDomains: displayInfo))
//                    }
                }
            } catch {
                //TODO: - Logout
                //TODO: - Save domains to onboarding data

//                (topViewController as? BaseViewControllerProtocol)?.showAlertWith(error: error, handler: { [weak self] _ in
//                    self?.dismiss(result: .failedToLoadParkedDomains)
//                })
            }
        }
    }
}
