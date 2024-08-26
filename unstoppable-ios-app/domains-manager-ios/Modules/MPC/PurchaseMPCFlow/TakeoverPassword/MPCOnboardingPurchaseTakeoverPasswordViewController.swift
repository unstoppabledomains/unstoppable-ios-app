//
//  MPCOnboardingPurchaseTakeoverPasswordViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.08.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseTakeoverPasswordViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .mpcPurchaseTakeoverPasswordOnboarding }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var dashesProgressConfiguration: DashesProgressView.Configuration { .init(numberOfDashes: 3) }
    var progress: Double? { 3 / 6 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCOnboardingPurchaseTakeoverPasswordViewController {
    func didEnterTakeoverPassword(_ password: String) {
        OnboardingData.mpcTakeoverCredentials?.password = password
        Task {
            try? await onboardingFlowManager?.handle(action: .didEnterTakeoverPassword)
        }
    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseTakeoverPasswordViewController {
    func setup() {
        addProgressDashesView(configuration: dashesProgressConfiguration)
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        let mpcView = PurchaseMPCWalletTakeoverPasswordView(analyticsName: analyticsName,
                                                            passwordCallback: { [weak self] password in
            DispatchQueue.main.async {
                self?.didEnterTakeoverPassword(password)
            }
        })
            .padding(.top, 40)
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingPurchaseTakeoverPasswordViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseTakeoverPassword }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseTakeoverPasswordViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}


