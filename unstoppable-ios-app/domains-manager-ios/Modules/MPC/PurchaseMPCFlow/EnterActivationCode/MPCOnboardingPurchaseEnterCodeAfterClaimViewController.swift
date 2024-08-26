//
//  MPCOnboardingPurchaseEnterCodeAfterClaimViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.08.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseEnterCodeAfterClaimViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .mpcPurchaseTakeoverCodeAfterClaimOnboarding }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var progress: Double? { nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCOnboardingPurchaseEnterCodeAfterClaimViewController {
    func didTakeoverWithCredentials(_ credentials: MPCTakeoverCredentials) {
        Task {
            try? await onboardingFlowManager?.handle(action: .didTakeoverMPCWallet(credentials))
        }
    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseEnterCodeAfterClaimViewController {
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
extension MPCOnboardingPurchaseEnterCodeAfterClaimViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseTakeoverProgress }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseEnterCodeAfterClaimViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}



