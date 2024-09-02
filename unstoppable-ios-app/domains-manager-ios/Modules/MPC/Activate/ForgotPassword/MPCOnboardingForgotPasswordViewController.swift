//
//  MPCOnboardingForgotPasswordViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.09.2024.
//

import SwiftUI

final class MPCOnboardingForgotPasswordViewController: BaseViewController, ViewWithDashesProgress {
    
    
    override var analyticsName: Analytics.ViewName { .mpcForgotPassword }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var progress: Double? { 1 / 4 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Setup methods
private extension MPCOnboardingForgotPasswordViewController {
    func setup() {
        addProgressDashesView()
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        let mpcView = MPCForgotPasswordView()
            .padding(.top, 40)
        
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingForgotPasswordViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcForgotPassword }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingForgotPasswordViewController: OnboardingDataHandling { }

