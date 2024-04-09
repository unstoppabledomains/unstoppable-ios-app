//
//  MPCEnterPassphraseViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

final class MPCEnterPassphraseViewController: BaseViewController, ViewWithDashesProgress {
    
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
private extension MPCEnterPassphraseViewController {
    func didCreateMPCWallet(_ wallet: UDWallet) {
        Task {
            try? await onboardingFlowManager?.handle(action: .didImportWallet(wallet))
        }
    }
}

// MARK: - Setup methods
private extension MPCEnterPassphraseViewController {
    func setup() {
        addProgressDashesView()
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        guard let code = onboardingFlowManager?.onboardingData.mpcCode else {
            cNavigationController?.popViewController(animated: true)
            Debugger.printFailure("No MPC Code passed", critical: true)
            return
        }
        let mpcView = MPCEnterPassphraseView(code: code) { [weak self] wallet in
            DispatchQueue.main.async {
                self?.didCreateMPCWallet(wallet)
            }
        }
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCEnterPassphraseViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcPassphrase }
}

// MARK: - OnboardingDataHandling
extension MPCEnterPassphraseViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}

