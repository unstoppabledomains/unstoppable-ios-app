//
//  MPCEnterCodeViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

final class MPCOnboardingEnterCredentialsViewController: BaseViewController, ViewWithDashesProgress {
        

    override var analyticsName: Analytics.ViewName { .mpcEnterCredentialsOnboarding }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var progress: Double? { 1 / 4 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCOnboardingEnterCredentialsViewController {
    func didEnterCredentials(_ credentials: MPCActivateCredentials) {
        OnboardingData.mpcCredentials = credentials
        onboardingFlowManager?.moveToStep(.mpcCode)
    }
    
    func didPressForgotPassword() {
        onboardingFlowManager?.moveToStep(.mpcForgotPassword)
    }
}

// MARK: - Setup methods
private extension MPCOnboardingEnterCredentialsViewController {
    func setup() {
        addProgressDashesView()
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        let mpcView = MPCEnterCredentialsView(mode: .freeInput(OnboardingData.mpcCredentials?.email),
                                              analyticsName: .mpcEnterCredentialsOnboarding,
                                              credentialsCallback: { [weak self] credentials in
            DispatchQueue.main.async {
                self?.didEnterCredentials(credentials)
            }
        }, forgotPasswordCallback: { [weak self] in
            self?.didPressForgotPassword()
        })
            .padding(.top, 40)

        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingEnterCredentialsViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcCredentials }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingEnterCredentialsViewController: OnboardingDataHandling {
    func willNavigateBack() {
        onboardingFlowManager?.onboardingData.mpcCode = nil
    }
}

