//
//  OnboardingConnectExternalWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.09.2022.
//

import UIKit

final class OnboardingConnectExternalWalletPresenter: ConnectExternalWalletViewPresenter {
    
    private weak var onboardingFlowManager: OnboardingFlowManager?
    override var analyticsName: Analytics.ViewName { .onboardingConnectExternalWalletSelection }
    
    init(view: ConnectExternalWalletViewProtocol,
         onboardingFlowManager: OnboardingFlowManager,
         udWalletsService: UDWalletsServiceProtocol,
         walletConnectClientService: WalletConnectClientServiceProtocol) {
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view,
                   udWalletsService: udWalletsService,
                   walletConnectClientService: walletConnectClientService)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            await MainActor.run {
                view?.setDashesProgress(0.5)
            }
        }
    }
    
    override func didConnectWallet(wallet: UDWallet) {
        super.didConnectWallet(wallet: wallet)
        
        onboardingFlowManager?.modifyOnboardingData() { $0.wallets = [wallet] }
        DispatchQueue.main.async { [weak self] in
            self?.onboardingFlowManager?.moveToStep(.externalWalletConnected)
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingConnectExternalWalletPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .connectExternalWallet }
}

// MARK: - OnboardingDataHandling
extension OnboardingConnectExternalWalletPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}

