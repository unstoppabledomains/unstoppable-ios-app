//
//  MPCEnterCodeViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

final class MPCEnterCodeOnboardingViewController: BaseViewController, ViewWithDashesProgress {
        

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
private extension MPCEnterCodeOnboardingViewController {
    func didEnterValidCode(_ code: String) {
        onboardingFlowManager?.onboardingData.mpcCode = code
        onboardingFlowManager?.moveToStep(.mpcSecret)
    }
}

// MARK: - Setup methods
private extension MPCEnterCodeOnboardingViewController {
    func setup() {
        addProgressDashesView()
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        let mpcView = MPCEnterCodeView { [weak self] code in
            DispatchQueue.main.async {
                self?.didEnterValidCode(code)
            }
        }
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCEnterCodeOnboardingViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcCode }
}

// MARK: - OnboardingDataHandling
extension MPCEnterCodeOnboardingViewController: OnboardingDataHandling {
    func willNavigateBack() {
        onboardingFlowManager?.onboardingData.mpcCode = nil
    }
}

