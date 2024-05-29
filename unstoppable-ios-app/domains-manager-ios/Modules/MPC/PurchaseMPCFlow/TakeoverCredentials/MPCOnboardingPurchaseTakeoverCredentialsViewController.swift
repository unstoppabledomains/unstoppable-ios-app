//
//  MPCOnboardingPurchaseTakeoverViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseTakeoverCredentialsViewController: BaseViewController, ViewWithDashesProgress {
    
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
private extension MPCOnboardingPurchaseTakeoverCredentialsViewController {
    func didEnterTakeoverCredentials(_ credentials: MPCActivateCredentials) {
        OnboardingData.mpcTakeoverCredentials = .init(email: credentials.email,
                                                      password: credentials.password)
        Task {
            try? await onboardingFlowManager?.handle(action: .didEnterTakeoverCredentials)
        }
    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseTakeoverCredentialsViewController {
    func setup() {
        addProgressDashesView()
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        let email = OnboardingData.mpcPurchaseCredentials?.email
        let mpcView = PurchaseMPCWalletTakeoverCredentialsView(purchaseEmail: email, credentialsCallback: { [weak self] credentials in
            DispatchQueue.main.async {
                self?.didEnterTakeoverCredentials(credentials)                
            }
        })
            .padding(.top, 40)
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingPurchaseTakeoverCredentialsViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseTakeoverCredentials }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseTakeoverCredentialsViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}


