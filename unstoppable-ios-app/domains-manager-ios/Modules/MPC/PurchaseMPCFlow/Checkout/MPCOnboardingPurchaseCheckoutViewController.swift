//
//  MPCOnboardingPurchaseCheckoutViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseCheckoutViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .onboardingMPCEnterCode }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var progress: Double? { 3 / 4 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCOnboardingPurchaseCheckoutViewController {
    func didPurchaseMPCWallet() {
        Task {
            try? await onboardingFlowManager?.handle(action: .didPurchaseMPCWallet)
        }
    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseCheckoutViewController {
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
        Task {
            try? await appContext.ecomPurchaseMPCWalletService.guestAuthWith(credentials: credentials)
        }
        
        let mpcView = PurchaseMPCWalletCheckoutView(credentials: credentials,
                                                    purchasedCallback: { [weak self] in
            self?.didPurchaseMPCWallet()
        })
            .padding(.top, 40)
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingPurchaseCheckoutViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseCheckout }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseCheckoutViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}

