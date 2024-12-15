//
//  MPCOnboardingPurchaseActivateAfterClaimViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.08.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseActivateAfterClaimViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .mpcPurchaseTakeoverActivateAfterClaimOnboarding }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var progress: Double? { nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCOnboardingPurchaseActivateAfterClaimViewController {
    func didActivateWallet(_ wallet: UDWallet) {
        Task {
            try? await onboardingFlowManager?.handle(action: .didImportWallet(wallet))
        }
    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseActivateAfterClaimViewController {
    func setup() {
        addProgressDashesView()
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        guard let credentials = OnboardingData.mpcCredentials,
              let code = onboardingFlowManager?.onboardingData.mpcCode else {
            cNavigationController?.popViewController(animated: true)
            Debugger.printFailure("No MPC Code passed", critical: true)
            return
        }
        
        let mpcView = MPCActivateWalletView(analyticsName: .mpcActivationOnboarding,
                                            flow: .activate(credentials),
                                            code: code,
                                            mpcWalletCreatedCallback: { [weak self] wallet in
            DispatchQueue.main.async {
                self?.didActivateWallet(wallet)
            }
        }, changeEmailCallback: nil)
            .padding(.top, 40)
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingPurchaseActivateAfterClaimViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseTakeoverActivateAfterClaim }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseActivateAfterClaimViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}

