//
//  CreateLocalWalletEnterBackupPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

final class EnterBackupCreateLocalWalletPresenter: EnterBackupBasePresenter {
    
    private weak var addWalletFlowManager: AddWalletFlowManager?
    private let udWalletsService: UDWalletsServiceProtocol
    private let wallet: UDWallet
    override var analyticsName: Analytics.ViewName { .enterBackupPasswordToBackupNewWallet }

    init(view: EnterBackupViewControllerProtocol,
         udWalletsService: UDWalletsServiceProtocol,
         wallet: UDWallet,
         addWalletFlowManager: AddWalletFlowManager) {
        self.addWalletFlowManager = addWalletFlowManager
        self.udWalletsService = udWalletsService
        self.wallet = wallet
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        view?.setDashesProgress(nil)
        view?.setSubtitle(String.Constants.addToBackupNewWalletSubtitle.localized())
        view?.setTitle(String.Constants.addToCurrentBackupNewWalletTitle.localized())
    }
    
    override func didTapContinueButton() {
        guard let view = self.view else { return }
                        
        let password = view.password
        do {
            let wallet = try udWalletsService.backUpWalletToCurrentCluster(wallet,
                                                                           withPassword: password)
            finishWith(wallet: wallet, password: password)
        } catch UDWalletBackUpError.alreadyBackedUp {
            var wallet = self.wallet
            wallet.hasBeenBackedUp = true
            finishWith(wallet: wallet, password: password)
        } catch UDWalletBackUpError.incorrectBackUpPassword {
            view.showError(String.Constants.incorrectPassword.localized())
        } catch {
            view.showSimpleAlert(title: String.Constants.saveToICloudFailedTitle.localized(),
                                 body: String.Constants.backupToICloudFailedMessage.localized())
        }
    }
}

// MARK: - Private methods
private extension EnterBackupCreateLocalWalletPresenter {
    func finishWith(wallet: UDWallet, password: String) {
        Vibration.success.vibrate()
        addWalletFlowManager?.wallet = wallet
        addWalletFlowManager?.moveToStep(.recoveryPhraseConfirmed(password: password))
    }
}
