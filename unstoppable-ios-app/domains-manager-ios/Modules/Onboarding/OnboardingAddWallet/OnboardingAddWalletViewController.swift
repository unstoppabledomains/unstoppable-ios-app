//
//  OnboardingAddWalletViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.04.2024.
//

import UIKit
import SwiftUI

final class OnboardingAddWalletViewController: BaseViewController, ViewWithDashesProgress {
    
    var onboardingFlowManager: OnboardingFlowManager!
    var progress: Double? { 0.25 }
    override var analyticsName: Analytics.ViewName { .onboardingAddWallet }
    
    static func instantiate() -> RestoreWalletViewController {
        RestoreWalletViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        Task {
            var prevTitleView: UIView?
            /// Progress view will be overlapped with previous title if not hidden. Temporary solution
            if let titleView = cNavigationBar?.navBarContentView.titleView,
               !(titleView is DashesProgressView) {
                prevTitleView = titleView
            }
            await MainActor.run {
                prevTitleView?.isHidden = true
                setDashesProgress(0.25)
            }
            await Task.sleep(seconds: 0.5)
            prevTitleView?.isHidden = false
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingAddWalletViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .createNewSelection }
}

// MARK: - OnboardingDataHandling
extension OnboardingAddWalletViewController: OnboardingDataHandling { }

// MARK: - Actions
private extension OnboardingAddWalletViewController {
    func didSelectRestoreOption(_ restoreOption: RestoreWalletType) {
        switch restoreOption {
        case .iCloud:
            guard iCloudWalletStorage.isICloudAvailable() else {
                showICloudDisabledAlert()
                return
            }
            
            onboardingFlowManager.moveToStep(.enterBackup)
        case .recoveryPhrase:
            onboardingFlowManager.moveToStep(.addManageWallet)
        case .watchWallet:
            onboardingFlowManager.moveToStep(.addWatchWallet)
        case .externalWallet:
            onboardingFlowManager.moveToStep(.connectExternalWallet)
        case .websiteAccount:
            onboardingFlowManager.moveToStep(.loginWithWebsite)
        case .mpc:
            onboardingFlowManager.moveToStep(.mpcCredentials)
        }
    }
}

// MARK: - Setup methods
private extension OnboardingAddWalletViewController {
    func setup() {
        setupDashesProgressView()
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        var restoreOptions = [[RestoreWalletType]]()
        let backedUpWallets = appContext.udWalletsService.fetchCloudWalletClusters().reduce([BackedUpWallet](), { $0 + $1.wallets })
        
        if !backedUpWallets.isEmpty {
            restoreOptions.append([.iCloud(value: iCLoudRestoreHintValue(backedUpWallets: backedUpWallets))])
        }
        
        restoreOptions.append([.mpc, .recoveryPhrase, .externalWallet, .websiteAccount])
        
        let mpcView = RestoreWalletView(options: restoreOptions) { [weak self] restoreOption in
            self?.logButtonPressedAnalyticEvents(button: restoreOption.analyticsName)
            self?.didSelectRestoreOption(restoreOption)
        }
        let vc = UIHostingController(rootView: mpcView)
        addChildViewController(vc, andEmbedToView: view)
    }
    
    func iCLoudRestoreHintValue(backedUpWallets: [BackedUpWallet]) -> String {
        String.Constants.pluralWallets.localized(backedUpWallets.count)
    }
    
    func setupDashesProgressView() {
        addProgressDashesView()
        self.dashesProgressView.setProgress(0.25)
    }
}
