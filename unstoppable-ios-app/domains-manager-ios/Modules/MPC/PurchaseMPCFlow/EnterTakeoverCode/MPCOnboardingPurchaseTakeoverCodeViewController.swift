//
//  MPCOnboardingPurchaseTakeoverCodeViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.08.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseTakeoverCodeViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .mpcPurchaseTakeoverCodeOnboarding }
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
private extension MPCOnboardingPurchaseTakeoverCodeViewController {
    func didEnterCode(_ code: String) {
        OnboardingData.mpcTakeoverCredentials?.code = code
        Task {
            try? await onboardingFlowManager?.handle(action: .didEnterTakeoverCode)
        }
    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseTakeoverCodeViewController {
    func setup() {
        addProgressDashesView(configuration: dashesProgressConfiguration)
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        let email = OnboardingData.mpcTakeoverCredentials?.email ?? ""
        let mpcView = MPCEnterCodeView(analyticsName: analyticsName,
                                       email: email,
                                       resendAction: { [weak self] email in
            self?.resendCode(email: email)
        }) { [weak self] code in
            DispatchQueue.main.async {
                self?.didEnterCode(code)
            }
        }
            .padding(.top, 40)
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
    
    func resendCode(email: String) {
        Task {
            try await appContext.claimMPCWalletService.sendVerificationCodeTo(email: email)
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingPurchaseTakeoverCodeViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseTakeoverCode }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseTakeoverCodeViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}

