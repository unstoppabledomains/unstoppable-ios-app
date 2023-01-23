//
//  EnterBackupToRestoreWalletsPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.05.2022.
//

import UIKit

typealias WalletsRestoredCallback = () -> ()

final class EnterBackupToRestoreWalletsPresenter: EnterBackupBasePresenter {
    
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    private let udWalletsService: UDWalletsServiceProtocol
    private var backup: UDWalletsService.WalletCluster
    var walletsRestoredCallback: WalletsRestoredCallback
    override var analyticsName: Analytics.ViewName { .enterBackupPasswordToRestoreWallets }

    init(view: EnterBackupViewControllerProtocol,
         backup: UDWalletsService.WalletCluster,
         udWalletsService: UDWalletsServiceProtocol,
         walletsRestoredCallback: @escaping WalletsRestoredCallback) {
        self.backup = backup
        self.udWalletsService = udWalletsService
        self.walletsRestoredCallback = walletsRestoredCallback
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        view?.setDashesProgress(nil)
        view?.setSubtitle(String.Constants.addBackupWalletSubtitle.localized())
    }
    
    override func didTapContinueButton() {
        guard let view = self.view else { return }
        
        let password = view.password
        // Get password hash
        guard let backUpPassword = WalletBackUpPassword(password) else {
            return
        }
        
        // Check password from selected back up
        guard backUpPassword.value == backup.passwordHash else {
            view.showError(String.Constants.incorrectPassword.localized())
            return
        }
        
        Task {
            do {
                let _ = try await udWalletsService.restoreAndInjectWallets(using: password)
                try SecureHashStorage.save(password: password)

                await MainActor.run {
                    Vibration.success.vibrate()
                    view.dismiss(animated: true, completion: walletsRestoredCallback)
                }
            } catch {
                await view.showAlertWith(error: error)
            }
        }
    }
}
