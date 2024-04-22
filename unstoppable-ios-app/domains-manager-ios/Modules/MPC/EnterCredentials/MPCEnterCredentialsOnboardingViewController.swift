//
//  MPCEnterCodeViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

final class MPCEnterCredentialsOnboardingViewController: BaseViewController, ViewWithDashesProgress {
        

    override var analyticsName: Analytics.ViewName { .onboardingMPCEnterCode }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var progress: Double? { 1 / 2 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCEnterCredentialsOnboardingViewController {
    func didEnterCrendentials(_ credentials: MPCImportCredentials) {
        OnboardingData.mpcCredentials = credentials
        onboardingFlowManager?.moveToStep(.mpcCode)
    }
}

// MARK: - Setup methods
private extension MPCEnterCredentialsOnboardingViewController {
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
extension MPCEnterCredentialsOnboardingViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcCredentials }
}

// MARK: - OnboardingDataHandling
extension MPCEnterCredentialsOnboardingViewController: OnboardingDataHandling {
    func willNavigateBack() {
        onboardingFlowManager?.onboardingData.mpcCode = nil
    }
}

