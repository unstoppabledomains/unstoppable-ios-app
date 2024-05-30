//
//  MPCOnboardingPurchaseUDAuthViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseUDAuthViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .mpcEnterCodeOnboarding }
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
private extension MPCOnboardingPurchaseUDAuthViewController {
    func didEnterCredentials(_ credentials: MPCPurchaseUDCredentials) {
        OnboardingData.mpcPurchaseCredentials = credentials
        Task {
            try? await onboardingFlowManager?.handle(action: .didEnterMPCPurchaseUDCredentials)
        }
    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseUDAuthViewController {
    func setup() {
        addProgressDashesView(configuration: dashesProgressConfiguration)
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        let mpcView = PurchaseMPCWalletUDAuthView(credentialsCallback: { [weak self] credentials in
            self?.didEnterCredentials(credentials)
        })
            .padding(.top, 40)
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingPurchaseUDAuthViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseAuth }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseUDAuthViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}

