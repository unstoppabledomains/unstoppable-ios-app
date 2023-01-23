//
//  OnboardingBackupWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

final class OnboardingBackupWalletPresenter: BaseBackupWalletPresenter {
    private weak var onboardingFlowManager: OnboardingFlowManager?
    private let udWalletsService: UDWalletsServiceProtocol
    override var progress: Double? { 0.75 }
    override var analyticsName: Analytics.ViewName { .onboardingSelectBackupWalletOptions }

    init(view: BackupWalletViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager,
         networkReachabilityService: NetworkReachabilityServiceProtocol?,
         udWalletsService: UDWalletsServiceProtocol) {
        self.onboardingFlowManager = onboardingFlowManager
        self.udWalletsService = udWalletsService
        super.init(view: view,
                   networkReachabilityService: networkReachabilityService)
    }
    
    override func viewDidLoad() {
        setupForCurrentFlow()
        
        Task {
            await MainActor.run {
                view?.setDashesProgress(0.75)
            }
        }
    }
    
    override func skipButtonDidPress() {
        onboardingFlowManager?.didFinishOnboarding()
    }
    
    override func didSelectICloudOption() {
        onboardingFlowManager?.moveToStep(.createPassword)
    }
    
    override func didSelectRecoveryPhraseOption() {
        onboardingFlowManager?.moveToStep(.recoveryPhrase)
    }
    
    override func networkStatusChanged() {
        setupForCurrentFlow()
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
        if case .sameUserWithoutWallets = self.onboardingFlowManager?.onboardingFlow {
            guard let wallet = onboardingFlowManager?.onboardingData.wallets.first else { return }
            
            udWalletsService.remove(wallet: wallet)
            onboardingFlowManager?.modifyOnboardingData(modifyingBlock: { $0.wallets = [] })
            Debugger.printWarning("Wallet \(wallet) has been removed")
            return
        }
        
        KeychainPrivateKeyStorage.instance.clear(for: .passcode)
        onboardingFlowManager?.modifyOnboardingData(modifyingBlock: { $0.passcode = nil })
        if case .newUser = onboardingFlowManager?.onboardingFlow {
            var settings = User.instance.getSettings()
            settings.touchIdActivated = false
            User.instance.update(settings: settings)
        }
    }
}

// MARK: - Private methods
private extension OnboardingBackupWalletPresenter {
    func setupForCurrentFlow() {
        let onboardingFlow = onboardingFlowManager?.onboardingFlow
        let isNetworkReachable = networkReachabilityService?.isReachable == true
        let isICloudAvailable = iCloudWalletStorage.isICloudAvailable()
        switch onboardingFlow {
        case .newUser, .sameUserWithoutWallets:
            let vaultsPlural = String.Constants.vault.localized().lowercased()
            view?.setTitle(String.Constants.backUpYourWallet.localized(vaultsPlural))
            
            if isICloudAvailable {
                view?.setBackupTypes([.iCloud(subtitle: String.Constants.recommended.localized(), isOnline: isNetworkReachable), .manual])
            } else {
                view?.setBackupTypes([.manual])
            }
            view?.setSkipButtonHidden(true)
            view?.setSubtitle(String.Constants.backUpYourWalletDescription.localized())
        case .existingUser:
            let wallets = udWalletsService.getUserWallets()
            let vaultsPlural: String
            if wallets.first(where: { $0.type == .generatedLocally || $0.type == .defaultGeneratedLocally }) != nil {
                vaultsPlural = String.Constants.pluralVaults.localized(wallets.count)
            } else {
                vaultsPlural = String.Constants.pluralWallets.localized(wallets.count)
            }
            
            view?.setTitle(String.Constants.backUpYourWallet.localized(vaultsPlural))
            view?.setBackupTypes([.iCloud(subtitle: nil, isOnline: isNetworkReachable)])
            view?.setSkipButtonHidden(false)
            view?.setSubtitle(String.Constants.backUpYourExistingWalletDescription.localized())
        case .none: return
        }
    }
}
