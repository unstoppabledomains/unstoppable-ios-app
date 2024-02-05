//
//  OnboardingHappyEndViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.11.2023.
//

import Foundation

final class OnboardingHappyEndViewPresenter: BaseHappyEndViewPresenter {
    
    override var analyticsName: Analytics.ViewName { .onboardingHappyEnd }
    
    override func viewDidLoad() {
        view?.setActionButtonEnabled(false)
        view?.setAgreement(visible: true)
        view?.setConfiguration(.onboarding)
    }
    
    override func actionButtonPressed() {
        if UserDefaults.onboardingData?.didRestoreWalletsFromBackUp == true {
            AppReviewService.shared.appReviewEventDidOccurs(event: .didRestoreWalletsFromBackUp)
        }
        UserDefaults.onboardingNavigationInfo = nil
        UserDefaults.onboardingData = nil
        
        var settings = User.instance.getSettings()
        settings.onboardingDone = true
        User.instance.update(settings: settings)
        
        ConfettiImageView.releaseAnimations()
        if let wallet = appContext.walletsDataService.selectedWallet {
            appContext.coreAppCoordinator.showHome(profile: .wallet(wallet))
        } else if let user = appContext.firebaseParkedDomainsAuthenticationService.firebaseUser {
            appContext.coreAppCoordinator.showHome(profile: .webAccount(user))
        }
    }
}
