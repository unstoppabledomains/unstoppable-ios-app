//
//  CreateLocalWalletEnterBackupPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit
import PromiseKit

final class CreateLocalWalletEnterBackupPresenter: BaseEnterBackupPresenter {
    
    private let addWalletFlowManager: AddWalletFlowManager

    init(view: EnterBackupViewControllerProtocol,
         addWalletFlowManager: AddWalletFlowManager) {
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        view?.setDashesProgress(nil)
        view?.setDistanceToDashesView(UIDevice.isDeviceWithNotch ? -14 : 12)
    }
    
    override func didTapContinueButton() {
        guard let view = self.view else { return }
                
        let password = view.password
        
        // TODO: - Roman verify
        let iCloudStorage = iCloudPrivateKeyStorage()
        let iCloudWalletStorage = iCloudWalletStorage(storage: iCloudStorage)
        let wallets = iCloudWalletStorage.findWallets(password: password)
        
        if !wallets.isEmpty {
            addWalletFlowManager.moveToStep(.recoveryPhraseConfirmed(password: password))
        } else {
            view.showError(String.Constants.incorrectPassword.localized())
        }
    }
}
