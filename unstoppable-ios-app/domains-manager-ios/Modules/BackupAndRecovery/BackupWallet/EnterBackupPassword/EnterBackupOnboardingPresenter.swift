//
//  OnboardingEnterBackupPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

final class EnterBackupOnboardingPresenter: EnterBackupBasePresenter {
    
    private weak var onboardingFlowManager: OnboardingFlowManager?
    private let udWalletsService: UDWalletsServiceProtocol
    override var progress: Double? { 0.5 }
    override var analyticsName: Analytics.ViewName { .onboardingEnterBackupPassword }

    init(view: EnterBackupViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager,
         udWalletsService: UDWalletsServiceProtocol) {
        self.onboardingFlowManager = onboardingFlowManager
        self.udWalletsService = udWalletsService
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.setSubtitle(String.Constants.addBackupWalletSubtitle.localized())
        Task {
            await MainActor.run {
                view?.setDashesProgress(0.5)
            }
        }
    }
    
    override func didTapContinueButton() {
        guard let view = self.view else { return }
        
        view.setContinueButtonEnabled(false)
        let password = view.password
        
        Task {
            do {
                let wallets = try await udWalletsService.restoreAndInjectWallets(using: password)
                try SecureHashStorage.save(password: password)
                
                await MainActor.run {
                    view.setContinueButtonEnabled(true)
                    didRestoreWallets(wallets)
                }
            } catch UDWalletsService.BackUpError.incorrectBackUpPassword {
                await MainActor.run {
                    view.setContinueButtonEnabled(true)
                    view.showError(String.Constants.incorrectPassword.localized())
                }
            } catch {
                let backedUpWallets = udWalletsService.fetchCloudWalletClusters().reduce([BackedUpWallet](), { $0 + $1.wallets })
                let walletName: String = backedUpWallets.containUDVault() ? String.Constants.pluralVaults : String.Constants.pluralWallets
                Debugger.printFailure("Failed to create a wallet from iCloud, error: \(error)", critical: true)
                await MainActor.run {
                    view.setContinueButtonEnabled(true)
                    view.showSimpleAlert(title: String.Constants.restoreFromICloudFailedTitle.localized(),
                                                body: String.Constants.restoreFromICloudFailedMessage.localized(walletName.localized(backedUpWallets.count)))
                }
            }
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension EnterBackupOnboardingPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .enterBackup }
}

// MARK: - OnboardingDataHandling
extension EnterBackupOnboardingPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}

// MARK: - Private methods
private extension EnterBackupOnboardingPresenter {
    func didRestoreWallets(_ wallets: [UDWallet]) {
        Vibration.success.vibrate()
        onboardingFlowManager?.modifyOnboardingData() {
            $0.wallets = wallets
            $0.didRestoreWalletsFromBackUp = true
        }
        if case .sameUserWithoutWallets = onboardingFlowManager?.onboardingFlow {
            self.onboardingFlowManager?.didFinishOnboarding()
        } else {
            self.onboardingFlowManager?.moveToStep(.protectWallet)
        }
    }
}
