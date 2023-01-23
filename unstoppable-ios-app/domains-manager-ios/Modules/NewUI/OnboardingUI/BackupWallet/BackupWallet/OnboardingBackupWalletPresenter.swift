//
//  OnboardingBackupWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

final class OnboardingBackupWalletPresenter: BaseBackupWalletPresenter {
    private let onboardingFlowManager: OnboardingFlowManager
    
    init(view: BackupWalletViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view)
    }
    
    override var numberOfWallets: Int {
        switch onboardingFlowManager.onboardingFlow {
        case .existingUser:
            return UDWalletsStorage.instance.getWalletsList(ownedBy: User.defaultId).count
        default:
            return 1
        }
    }
    
    override func viewDidLoad() {
        setupForCurrentFlow()
    }
    
    override func skipButtonDidPress() {
        onboardingFlowManager.didFinishOnboarding()
    }
    
    override func didSelectICloudOption() {
        onboardingFlowManager.moveToStep(.createPassword)
    }
    
    override func didSelectRecoveryPhraseOption() {
        onboardingFlowManager.moveToStep(.recoveryPhrase)
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingBackupWalletPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .backupWallet }
}

// MARK: - OnboardingDataHandling
extension OnboardingBackupWalletPresenter: OnboardingDataHandling {
    func willNavigateBack() {
        KeychainPrivateKeyStorage.instance.clear(for: .passcode)
        onboardingFlowManager.modifyOnboardingData(modifyingBlock: { $0.passcode = nil })
        if case .newUser = onboardingFlowManager.onboardingFlow {
            var settings = User.instance.getSettings()
            settings.touchIdActivated = false
            User.instance.update(settings: settings)
        }
    }
}

// MARK: - Private methods
private extension OnboardingBackupWalletPresenter {
    func setupForCurrentFlow() {
        let onboardingFlow = onboardingFlowManager.onboardingFlow
        
        switch onboardingFlow {
        case .newUser:
            view?.setBackupTypes(BackupWalletViewController.BackupType.allCases)
            view?.setSkipButtonHidden(true)
            view?.setSubtitle(String.Constants.backUpYourWalletDescription.localized())
        case .existingUser:
            view?.setBackupTypes([.iCloud])
            view?.setSkipButtonHidden(false)
            view?.setSubtitle(String.Constants.backUpYourExistingWalletDescription.localized())
        }
    }
}
