//
//  MPCOnboardingActivateWalletViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.04.2024.
//


import SwiftUI

final class MPCOnboardingActivateWalletViewController: BaseViewController, ViewWithDashesProgress {
    
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
private extension MPCOnboardingActivateWalletViewController {
    func didCreateMPCWallet(_ wallet: UDWallet) {
        Task {
            try? await onboardingFlowManager?.handle(action: .didImportWallet(wallet))
        }
    }
}

// MARK: - Setup methods
private extension MPCOnboardingActivateWalletViewController {
    func setup() {
        addProgressDashesView()
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        guard let credentials = OnboardingData.mpcCredentials,
              let code = onboardingFlowManager?.onboardingData.mpcCode else {
            cNavigationController?.popViewController(animated: true)
            Debugger.printFailure("No MPC Code passed", critical: true)
            return
        }
        let mpcView = MPCActivateWalletView(credentials: credentials,
                                            code: code) { [weak self] wallet in
            DispatchQueue.main.async {
                self?.didCreateMPCWallet(wallet)
            }
        }
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
}

// MARK: - OnboardingNavigationHandler
extension MPCOnboardingActivateWalletViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .mpcActivate }
}

// MARK: - OnboardingDataHandling
extension MPCOnboardingActivateWalletViewController: OnboardingDataHandling {
    func willNavigateBack() { }
}

