//
//  BackupCreatedLocalWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

final class BackupCreatedLocalWalletPresenter: BaseBackupWalletPresenter {
    
    private weak var addWalletFlowManager: AddWalletFlowManager?
    let walletSource: WalletSource

    init(view: BackupWalletViewControllerProtocol,
         addWalletFlowManager: AddWalletFlowManager,
         walletSource: WalletSource,
         networkReachabilityService: NetworkReachabilityServiceProtocol?) {
        self.addWalletFlowManager = addWalletFlowManager
        self.walletSource = walletSource
        super.init(view: view,
                   networkReachabilityService: networkReachabilityService)
    }
    
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .selectBackupWalletOptionsForNewWallet }
    
    override func viewDidLoad() {
        view?.setDashesProgress(nil)
        setupForCurrentFlow()
    }
    
    override func didSelectICloudOption() {
        let iCloudStorage = iCloudPrivateKeyStorage()
        let iCloudWalletStorage = iCloudWalletStorage(storage: iCloudStorage)
        if iCloudWalletStorage.numberOfSavedWallets() > 0 {
            addWalletFlowManager?.moveToStep(.enterBackup)
        } else {
            addWalletFlowManager?.moveToStep(.createPassword)
        }
    }
    
    override func didSelectRecoveryPhraseOption() {
        addWalletFlowManager?.moveToStep(.recoveryPhrase)
    }
    
    override func skipButtonDidPress() {
        addWalletFlowManager?.didFinishAddWalletFlow()
    }
    
    override func networkStatusChanged() {
        setupForCurrentFlow()
    }
}

// MARK: - Private methods
private extension BackupCreatedLocalWalletPresenter {
    func setupForCurrentFlow() {
        let isNetworkReachable = networkReachabilityService?.isReachable == true
        
        switch walletSource {
        case .locallyCreated:
            let vaultsPlural = String.Constants.vault.localized().lowercased()
            view?.setTitle(String.Constants.backUpYourWallet.localized(vaultsPlural))
            view?.setSubtitle(String.Constants.backUpYourWalletDescription.localized())
            view?.setBackupTypes([.iCloud(subtitle: nil, isOnline: isNetworkReachable), .manual])
            view?.setSkipButtonHidden(true)
        case .imported:
            let vaultsPlural = String.Constants.wallet.localized().lowercased()
            view?.setTitle(String.Constants.backUpYourWallet.localized(vaultsPlural))
            view?.setSubtitle(String.Constants.backUpYourExistingWalletDescription.localized())
            view?.setBackupTypes([.iCloud(subtitle: nil, isOnline: isNetworkReachable)])
            view?.setSkipButtonHidden(false)
        }
    }
}

extension BackupCreatedLocalWalletPresenter {
    enum WalletSource {
        case locallyCreated
        case imported
    }
}
