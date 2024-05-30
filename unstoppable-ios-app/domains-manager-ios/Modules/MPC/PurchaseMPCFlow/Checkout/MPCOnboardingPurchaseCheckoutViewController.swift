//
//  MPCOnboardingPurchaseCheckoutViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseCheckoutViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .mpcEnterCodeOnboarding }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var dashesProgressConfiguration: DashesProgressView.Configuration { .init(numberOfDashes: 3) }
    var progress: Double? { 0.5 }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCOnboardingPurchaseCheckoutViewController {
    func didPurchaseMPCWallet(_ result: PurchaseMPCWallet.PurchaseResult) {
        Task { @MainActor in 
            switch result {
            case .purchased:
                try? await onboardingFlowManager?.handle(action: .didPurchaseMPCWallet)
            case .alreadyHaveWallet:
                try? await onboardingFlowManager?.handle(action: .alreadyPurchasedMPCWallet)                
            }
        }
    }
    
    func didUpdatePurchaseState(_ state: MPCWalletPurchasingState) {
        let isBackButtonHidden: Bool
    
        switch state {
        case .preparing, .failed, .readyToPurchase:
            isBackButtonHidden = false
        case .purchasing:
            isBackButtonHidden = true
        }

        DispatchQueue.main.async {
            self.cNavigationBar?.setBackButton(hidden: isBackButtonHidden)
        }
    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseCheckoutViewController {
    func setup() {
        addProgressDashesView(configuration: dashesProgressConfiguration)
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
                                                    purchaseStateCallback: { [weak self] state in
            self?.didUpdatePurchaseState(state)
        }, purchasedCallback: { [weak self] result in
            self?.didPurchaseMPCWallet(result)
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

