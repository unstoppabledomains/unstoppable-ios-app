//
//  MPCOnboardingPurchaseTakeoverViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseTakeoverEmailViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .mpcPurchaseTakeoverEmailOnboarding }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var dashesProgressConfiguration: DashesProgressView.Configuration { .init(numberOfDashes: 3) }
    var progress: Double? { 1 / 6 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCOnboardingPurchaseTakeoverEmailViewController {
    func didEnterTakeoverEmail(_ email: String) {
        OnboardingData.mpcTakeoverCredentials = .init(email: email,
                                                      password: "")
        Task {
            try? await onboardingFlowManager?.handle(action: .didEnterTakeoverEmail)
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
        let mpcView = PurchaseMPCWalletTakeoverEmailView(analyticsName: analyticsName,
                                                         emailCallback: { [weak self] email in
            DispatchQueue.main.async {
                self?.didEnterTakeoverEmail(email)
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
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseTakeoverEmail }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseTakeoverEmailViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}


