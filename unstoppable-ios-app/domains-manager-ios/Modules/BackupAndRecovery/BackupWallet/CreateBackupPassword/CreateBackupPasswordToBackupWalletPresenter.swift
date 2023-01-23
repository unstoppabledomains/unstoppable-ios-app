//
//  CreateBackupPasswordToBackupWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import Foundation

final class CreateBackupPasswordToBackupWalletPresenter: CreateBackupPasswordBasePresenter {

    var wallet: UDWallet
    var walletBackedUpCallback: WalletBackedUpCallback
    override var walletToBackUp: UDWallet? { wallet }
    override var analyticsName: Analytics.ViewName { .createBackupPasswordToBackupWallet }
    
    init(view: CreatePasswordViewControllerProtocol,
         wallet: UDWallet,
         udWalletsService: UDWalletsServiceProtocol,
         walletBackedUpCallback: @escaping WalletBackedUpCallback) {
        self.wallet = wallet
        self.walletBackedUpCallback = walletBackedUpCallback
        super.init(view: view,
                   udWalletsService: udWalletsService)
    }
    
    override func viewDidLoad() {
        view?.setDashesProgress(nil)
    }
    
    override func didSaveWallet(_ wallet: UDWallet, underBackUpPassword password: String) {
        super.didSaveWallet(wallet, underBackUpPassword: password)
        view?.dismiss(animated: true, completion: { [weak self] in
            self?.view?.view.endEditing(true)
            self?.walletBackedUpCallback(wallet)
        })
    }
}
