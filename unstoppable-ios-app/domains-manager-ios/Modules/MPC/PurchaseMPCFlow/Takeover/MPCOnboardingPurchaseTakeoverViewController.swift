//
//  MPCOnboardingPurchaseTakeoverViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseTakeoverViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .mpcEnterCodeOnboarding }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var progress: Double? { 3 / 4 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCOnboardingPurchaseTakeoverViewController {
    func didTakeoverWithCredentials(_ credentials: MPCActivateCredentials) {
        OnboardingData.mpcCredentials = credentials
        onboardingFlowManager?.moveToStep(.mpcCode)
    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseTakeoverViewController {
    func setup() {
        addProgressDashesView()
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        let mpcView = PurchaseMPCWalletTakeoverView(credentialsCallback: { [weak self] credentials in
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
extension MPCOnboardingPurchaseTakeoverViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseTakeover }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseTakeoverViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}

