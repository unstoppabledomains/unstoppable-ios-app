//
//  MPCOnboardingPurchaseTakeoverRecoveryViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.05.2024.
//

import SwiftUI

final class MPCOnboardingPurchaseTakeoverRecoveryViewController: BaseViewController, ViewWithDashesProgress {
    
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
private extension MPCOnboardingPurchaseTakeoverRecoveryViewController {
    func didSelectTo(sendRecoveryLink: Bool) {
        OnboardingData.mpcTakeoverCredentials?.sendRecoveryLink = sendRecoveryLink
        Task {
            
        }
    }
    
//    func didTakeoverWithCredentials(_ sendRecoveryLink: Bool) {
//        OnboardingData.mpcCredentials = credentials
//        onboardingFlowManager?.moveToStep(.mpcCode)
//    }
}

// MARK: - Setup methods
private extension MPCOnboardingPurchaseTakeoverRecoveryViewController {
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
        
        let mpcView = PurchaseMPCWalletTakeoverRecoveryView(email: credentials.email,
                                                            confirmCallback: { [weak self] sendRecoveryLink in
            DispatchQueue.main.async {
                self?.didSelectTo(sendRecoveryLink: sendRecoveryLink)
            }
        })
            .padding(.top, 40)
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingPurchaseTakeoverRecoveryViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPurchaseTakeoverRecovery }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingPurchaseTakeoverRecoveryViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}
