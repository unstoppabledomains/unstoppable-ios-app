//
//  MPCOnboardingPurchaseAlreadyHaveWalletViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.05.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseAlreadyHaveWalletViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .mpcEnterCodeOnboarding }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var progress: Double? { nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCOnboardingPurchaseAlreadyHaveWalletViewController {
    func didSelectAction(_ action: PurchaseMPCWallet.AlreadyHaveWalletAction) {
        Task {
            switch action {
            case .useDifferentEmail:
                try? await onboardingFlowManager?.handle(action: .alreadyPurchasedMPCWalletUseDifferentEmail)
            case .importMPC:
                try? await onboardingFlowManager?.handle(action: .alreadyPurchasedMPCWalletImportMPC)                
            }
        }
    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseAlreadyHaveWalletViewController {
    func setup() {
        addProgressDashesView()
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        guard let credentials = OnboardingData.mpcPurchaseCredentials else {
            cNavigationController?.popViewController(animated: true)
            Debugger.printFailure("No Credentials passed", critical: true)
            return
        }
        
        let mpcView = PurchaseMPCWalletAlreadyHaveWalletView(email: credentials.email,
                                                             callback: { [weak self] action in
            self?.didSelectAction(action)
        })
            .padding(.top, 40)
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingPurchaseAlreadyHaveWalletViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseAlreadyHaveWallet }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseAlreadyHaveWalletViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}


