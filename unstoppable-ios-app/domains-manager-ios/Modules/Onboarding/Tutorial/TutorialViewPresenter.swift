//
//  TutorialViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import Foundation

@MainActor
protocol TutorialViewPresenterProtocol: BasePresenterProtocol {
    func didPressCreateNewWalletButton()
    func didPressAddExistingWalletButton()
    func didPressBuyDomain()
}

final class TutorialViewPresenter {
    private weak var onboardingFlowManager: OnboardingFlowManager?
    weak var view: TutorialViewControllerProtocol?
    
    init(view: TutorialViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        self.view = view
        self.onboardingFlowManager = onboardingFlowManager
    }
}

// MARK: - TutorialViewPresenterProtocol
extension TutorialViewPresenter: TutorialViewPresenterProtocol {
    func viewDidLoad() {
        
    }
    
    func didPressCreateNewWalletButton() {
        onboardingFlowManager?.moveToStep(.createNewSelection)
    }
    
    func didPressAddExistingWalletButton() {
        onboardingFlowManager?.setNewUserOnboardingSubFlow(.restore)
        onboardingFlowManager?.moveToStep(.restoreWallet)
    }
    
    func didPressBuyDomain() {
        guard let view = self.view else { return }
        
        UDRouter().showBuyDomainsWebView(in: view, requireMintingCallback: { details in
            UserDefaults.onboardingDomainsPurchasedDetails = details
        })
    }
}

