//
//  CreateBackupPasswordCreatedLocalWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import Foundation

final class CreateBackupPasswordForNewLocalWalletPresenter: CreateBackupPasswordBasePresenter {
    private weak var addWalletFlowManager: AddWalletFlowManager?
    override var walletToBackUp: UDWallet? { addWalletFlowManager?.wallet }
    override var analyticsName: Analytics.ViewName { .createBackupPasswordForNewWallet }

    init(view: CreatePasswordViewControllerProtocol,
         addWalletFlowManager: AddWalletFlowManager,
         udWalletsService: UDWalletsServiceProtocol) {
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view,
                   udWalletsService: udWalletsService)
    }
    
    override func viewDidLoad() {
        view?.setDashesProgress(nil)
    }
    
    override func didSaveWallet(_ wallet: UDWallet, underBackUpPassword password: String) {
        super.didSaveWallet(wallet, underBackUpPassword: password)
        addWalletFlowManager?.wallet = wallet
        addWalletFlowManager?.moveToStep(.recoveryPhraseConfirmed(password: password))
    }
}
