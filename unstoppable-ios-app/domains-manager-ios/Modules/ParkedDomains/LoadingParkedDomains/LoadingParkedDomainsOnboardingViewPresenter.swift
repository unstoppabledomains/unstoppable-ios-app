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
                    if parkedDomains.isEmpty {
                        onboardingFlowManager?.moveToStep(.noParkedDomains)
                    } else {
                        onboardingFlowManager?.modifyOnboardingData { onboardingData in
                            onboardingData.parkedDomains = displayInfo
                        }
                        onboardingFlowManager?.moveToStep(.parkedDomainsFound)
                    }
                }
            } catch {
                await view?.showAlertWith(error: error, handler: { _ in
                    appContext.firebaseInteractionService.logout()
                })
            }
        }
    }
}
