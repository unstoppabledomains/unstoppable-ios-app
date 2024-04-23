//
//  MPCEnterPassphraseViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

final class MPCOnboardingEnterCodeViewController: BaseViewController, ViewWithDashesProgress {
    
    override var analyticsName: Analytics.ViewName { .onboardingMPCEnterCode }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    weak var onboardingFlowManager: OnboardingFlowManager?
    var progress: Double? { 3 / 4 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension MPCOnboardingEnterCodeViewController {
    func didEnterCode(_ code: String) {
        onboardingFlowManager?.modifyOnboardingData(modifyingBlock: { $0.mpcCode = code })
        onboardingFlowManager?.moveToStep(.mpcActivate)
    }
}

// MARK: - Setup methods
private extension MPCOnboardingEnterCodeViewController {
    func setup() {
        addProgressDashesView()
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        guard let email = OnboardingData.mpcCredentials?.email else {
            cNavigationController?.popViewController(animated: true)
            Debugger.printFailure("No Email passed", critical: true)
            return
        }
        let mpcView = MPCEnterCodeView(email: email) { [weak self] code in
            DispatchQueue.main.async {
                self?.didEnterCode(code)
            }
        }
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingEnterCodeViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcCode }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingEnterCodeViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}

