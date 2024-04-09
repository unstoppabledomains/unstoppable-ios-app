//
//  OnboardingAddWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

final class OnboardingAddWalletPresenter: BaseAddWalletPresenter {
    private weak var onboardingFlowManager: OnboardingFlowManager?
    override var progress: Double? { 0.5 }
    override var analyticsName: Analytics.ViewName { .onboardingImportWallet }

    init(view: AddWalletViewControllerProtocol,
         walletType: RestorationWalletType,
         udWalletsService: UDWalletsServiceProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view, walletType: walletType, udWalletsService: udWalletsService)
    }
    
    @MainActor
    override func didCreateWallet(wallet: UDWallet) {
        super.didCreateWallet(wallet: wallet)
        Task {
            try? await onboardingFlowManager?.handle(action: .didImportWallet(wallet))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            await MainActor.run {
                view?.startEditing()
                view?.setDashesProgress(0.5)
            }
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingAddWalletPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep {
        switch walletType {
        case .verified:
            return .addManageWallet
        case .readOnly:
            return .addWatchWallet
        }
    }
}

// MARK: - OnboardingDataHandling
extension OnboardingAddWalletPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}
