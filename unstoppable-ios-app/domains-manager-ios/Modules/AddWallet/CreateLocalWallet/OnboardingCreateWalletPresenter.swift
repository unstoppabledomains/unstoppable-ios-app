//
//  CreateWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

final class OnboardingCreateWalletPresenter: BaseCreateWalletPresenter {
    private weak var onboardingFlowManager: OnboardingFlowManager?
    override var analyticsName: Analytics.ViewName { .onboardingCreateUDVault }

    init(view: CreateWalletViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager,
         udWalletsService: UDWalletsServiceProtocol) {
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view,
                   udWalletsService: udWalletsService)
        self.wallet = onboardingFlowManager.onboardingData.wallets.first
    }
    
    override func viewDidLoad() {
        view?.setStyle(.fullUI)
        Task {
            await MainActor.run {
                view?.setDashesProgress(0.25)
            }
        }
    }
    
    override func walletCreated(_ wallet: UDWallet) {
        onboardingFlowManager?.modifyOnboardingData() { $0.wallets = [wallet] }
        onboardingFlowManager?.setNewUserOnboardingSubFlow(.create)
        if case .sameUserWithoutWallets = onboardingFlowManager?.onboardingFlow {
            self.onboardingFlowManager?.moveToStep(.backupWallet)
        } else {
            self.onboardingFlowManager?.moveToStep(.protectWallet)
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingCreateWalletPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .createWallet }
}

// MARK: - OnboardingDataHandling
extension OnboardingCreateWalletPresenter: OnboardingDataHandling {
    func willNavigateBack() {
        onboardingFlowManager?.setNewUserOnboardingSubFlow(.restore)
    }
}
