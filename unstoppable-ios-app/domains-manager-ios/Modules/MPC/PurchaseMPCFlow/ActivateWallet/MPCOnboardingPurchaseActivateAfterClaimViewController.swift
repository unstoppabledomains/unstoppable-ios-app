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
    func didTakeoverWithCredentials(_ credentials: MPCTakeoverCredentials) {
        Task {
            try? await onboardingFlowManager?.handle(action: .didTakeoverMPCWallet(credentials))
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
        guard let credentials = OnboardingData.mpcTakeoverCredentials else {
            cNavigationController?.popViewController(animated: true)
            Debugger.printFailure("No Credentials passed", critical: true)
            return
        }
        
        let mpcView = PurchaseMPCWalletTakeoverProgressView(analyticsName: analyticsName,
                                                            credentials: credentials,
                                                            finishCallback: { [weak self] in
            DispatchQueue.main.async {
                self?.didTakeoverWithCredentials(credentials)
            }
        })
            .padding(.top, 40)
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingPurchaseActivateAfterClaimViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseTakeoverProgress }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseActivateAfterClaimViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}

