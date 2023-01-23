//
//  OnboardingConfirmWordsPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

final class OnboardingConfirmWordsPresenter: BaseConfirmRecoveryWordsPresenter {
    
    private weak var onboardingFlowManager: OnboardingFlowManager?
    override var wallet: UDWallet? { onboardingFlowManager?.onboardingData.wallets.first }
    override var progress: Double? { 0.75 }
    override var analyticsName: Analytics.ViewName { .onboardingConfirmRecoveryWords }
    
    init(view: ConfirmWordsViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            await MainActor.run {
                view?.setDashesProgress(0.75)
            }
        }
    }
    
    override func didConfirmWords() {
        onboardingFlowManager?.didFinishOnboarding()
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingConfirmWordsPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .confirmWords }
}

// MARK: - OnboardingDataHandling
extension OnboardingConfirmWordsPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}
