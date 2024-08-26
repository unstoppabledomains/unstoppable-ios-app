//
//  MPCOnboardingPurchaseTakeoverViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseTakeoverEmailViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .mpcPurchaseTakeoverCredentialsOnboarding }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var dashesProgressConfiguration: DashesProgressView.Configuration { .init(numberOfDashes: 3) }
    var progress: Double? { 2 / 3 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCOnboardingPurchaseTakeoverEmailViewController {
    func didEnterTakeoverCredentials(_ credentials: MPCActivateCredentials) {
        OnboardingData.mpcTakeoverCredentials = .init(email: credentials.email,
                                                      password: credentials.password)
        Task {
            try? await onboardingFlowManager?.handle(action: .didEnterTakeoverCredentials)
        }
    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseTakeoverEmailViewController {
    func setup() {
        addProgressDashesView(configuration: dashesProgressConfiguration)
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        let email = OnboardingData.mpcPurchaseCredentials?.email
        let mpcView = PurchaseMPCWalletTakeoverEmailView(analyticsName: analyticsName,
                                                         emailCallback: { [weak self] credentials in
            DispatchQueue.main.async {
//                self?.didEnterTakeoverCredentials(credentials)                
            }
        })
            .padding(.top, 40)
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingPurchaseTakeoverEmailViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseTakeoverCredentials }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseTakeoverEmailViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}


