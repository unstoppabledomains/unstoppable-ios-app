//
//  EnterBackupToBackupWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import UIKit

typealias WalletBackedUpCallback = (UDWallet) -> ()

final class EnterBackupToBackupWalletPresenter: EnterBackupBasePresenter {
       
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    private let udWalletsService: UDWalletsServiceProtocol
    private var wallet: UDWallet
    var walletBackedUpCallback: WalletBackedUpCallback
    override var analyticsName: Analytics.ViewName { .enterBackupPasswordToBackupWallet }

    init(view: EnterBackupViewControllerProtocol,
         wallet: UDWallet,
         udWalletsService: UDWalletsServiceProtocol,
         walletBackedUpCallback: @escaping WalletBackedUpCallback) {
        self.wallet = wallet
        self.udWalletsService = udWalletsService
        self.walletBackedUpCallback = walletBackedUpCallback
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        view?.setDashesProgress(nil)
        view?.setSubtitle(String.Constants.addToBackupNewWalletSubtitle.localized())
        view?.setTitle(String.Constants.addToCurrentBackupNewWalletTitle.localized())
    }
    
    override func didTapContinueButton() {
        guard let view = self.view else { return }
        
        do {
            let password = view.password
            let backedUpWallet = try udWalletsService.backUpWalletToCurrentCluster(wallet, withPassword: password)
            finishWith(backedUpWallet: backedUpWallet)
        } catch UDWalletBackUpError.alreadyBackedUp {
            var backedUpWallet = self.wallet
            backedUpWallet.hasBeenBackedUp = true
            finishWith(backedUpWallet: backedUpWallet)
        } catch UDWalletBackUpError.incorrectBackUpPassword {
            view.showError(String.Constants.incorrectPassword.localized())
        } catch {
            view.showSimpleAlert(title: String.Constants.saveToICloudFailedTitle.localized(),
                                 body: String.Constants.backupToICloudFailedMessage.localized())
        }
    }
}

// MARK: - Private methods
private extension EnterBackupToBackupWalletPresenter {
    func finishWith(backedUpWallet: UDWallet) {
        Vibration.success.vibrate()
        view?.dismiss(animated: true, completion: { [weak self] in
            self?.walletBackedUpCallback(backedUpWallet)
        })
    }
}
