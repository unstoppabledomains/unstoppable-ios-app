//
//  MPCEnterCodeViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

final class MPCOnboardingEnterCredentialsViewController: BaseViewController, ViewWithDashesProgress {
        

    override var analyticsName: Analytics.ViewName { .onboardingMPCEnterCode }
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
    func didEnterCrendentials(_ credentials: MPCActivateCredentials) {
        OnboardingData.mpcCredentials = credentials
        onboardingFlowManager?.moveToStep(.mpcCode)
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
        let mpcView = MPCEnterCredentialsView { [weak self] code in
            DispatchQueue.main.async {
                self?.didEnterCrendentials(code)
            }
        }
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

