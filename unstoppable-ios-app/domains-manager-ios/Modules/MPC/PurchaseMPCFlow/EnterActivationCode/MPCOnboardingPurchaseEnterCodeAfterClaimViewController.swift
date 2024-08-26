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
    private var didSendCode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !didSendCode,
        let credentials = OnboardingData.mpcCredentials else { return }
        
        didSendCode = true
        
        resendCode(email: credentials.email)
    }
}

// MARK: - Private methods
private extension MPCOnboardingPurchaseEnterCodeAfterClaimViewController {
    func didEnterCode(_ code: String) {
        onboardingFlowManager?.modifyOnboardingData(modifyingBlock: { $0.mpcCode = code })
        Task {
            try? await onboardingFlowManager?.handle(action: .didEnterActivationCodeAfterPurchase)
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
        guard let credentials = OnboardingData.mpcCredentials else {
            cNavigationController?.popViewController(animated: true)
            Debugger.printFailure("No Credentials passed", critical: true)
            return
        }
        
        let mpcView = MPCEnterCodeView(analyticsName: analyticsName,
                                       email: credentials.email,
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
            try await appContext.mpcWalletsService.sendBootstrapCodeTo(email: email)
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingPurchaseEnterCodeAfterClaimViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseTakeoverCodeAfterClaim }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseEnterCodeAfterClaimViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}



