//
//  MPCOnboardingPurchaseAlmostThereViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.08.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseAlmostThereViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .mpcPurchaseTakeoverAlmostThereOnboarding }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var progress: Double? { nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCOnboardingPurchaseAlmostThereViewController {
    func didPressContinue() {
        Task {
            try? await onboardingFlowManager?.handle(action: .didTapContinueAfterTakeover)
        }
    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseAlmostThereViewController {
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
        
        let mpcView = PurchaseMPCWalletAlmostThereView(analyticsName: analyticsName,
                                                       continueCallback: { [weak self] in
            DispatchQueue.main.async {
                self?.didPressContinue()
            }
        })
            .padding(.top, 40)
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingPurchaseAlmostThereViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseTakeoverAlmostThere }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseAlmostThereViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}



