//
//  BackupCreatedLocalWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

final class BackupCreatedLocalWalletPresenter: BaseBackupWalletPresenter {
    private let addWalletFlowManager: AddWalletFlowManager

    init(view: BackupWalletViewControllerProtocol,
         addWalletFlowManager: AddWalletFlowManager) {
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view)
    }
    
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    
    override func viewDidLoad() {
        view?.setDashesProgress(nil)
        view?.setDistanceToDashesView(UIDevice.isDeviceWithNotch ? -14 : 12)
        switch addWalletFlowManager.mode {
        case .createLocal:
            view?.setSubtitle(String.Constants.backUpYourWalletDescription.localized())
            view?.setBackupTypes(BackupWalletViewController.BackupType.allCases)
            view?.setSkipButtonHidden(true)
        case .importExternal:
            view?.setSubtitle(String.Constants.protectYourWalletDescription.localized())
            view?.setBackupTypes([.iCloud])
            view?.setSkipButtonHidden(false)
        }
    }
    
    override func didSelectICloudOption() {
        // TODO: - Roman verify
        let wallets = UDWalletsStorage.instance
            .getWalletsList(ownedBy: User.defaultId)
            .filter{ $0.walletState == .verified && $0.hasBeenBackedUp == true }
        if wallets.isEmpty {
            addWalletFlowManager.moveToStep(.createPassword)
        } else {
            addWalletFlowManager.moveToStep(.enterBackup)
        }
    }
    
    override func didSelectRecoveryPhraseOption() {
        addWalletFlowManager.moveToStep(.recoveryPhrase)
    }
    
    override func skipButtonDidPress() {
        addWalletFlowManager.didFinishCreateWalletFlow()
    }
}
