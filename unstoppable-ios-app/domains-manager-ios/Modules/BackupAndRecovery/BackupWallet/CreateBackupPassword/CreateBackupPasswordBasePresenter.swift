//
//  BaseCreateBackupPasswordPresenterProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

protocol CreateBackupPasswordPresenterProtocol: BasePresenterProtocol {
    var isShowingHelp: Bool { get }
    var progress: Double? { get }
    var analyticsName: Analytics.ViewName { get }
    
    func createPasswordButtonPressed()
    func didTapLearnMore()
}

class CreateBackupPasswordBasePresenter {
    private(set) var isShowingHelp = false
    weak var view: CreatePasswordViewControllerProtocol?
    private let udWalletsService: UDWalletsServiceProtocol
    var walletToBackUp: UDWallet? { nil } // Should be overridden
    var progress: Double? { nil }
    var analyticsName: Analytics.ViewName { .unspecified }
    
    init(view: CreatePasswordViewControllerProtocol,
         udWalletsService: UDWalletsServiceProtocol) {
        self.view = view
        self.udWalletsService = udWalletsService
    }
    
    func viewDidLoad() { }
    func didSaveWallet(_ wallet: UDWallet, underBackUpPassword password: String) {
        Vibration.success.vibrate()
    }
    func failedToBackUpWallet(error: Error) {
        view?.showSimpleAlert(title: String.Constants.saveToICloudFailedTitle.localized(),
                             body: String.Constants.backupToICloudFailedMessage.localized())
    }
}

// MARK: - CreatePasswordPresenterProtocol
extension CreateBackupPasswordBasePresenter: CreateBackupPasswordPresenterProtocol {
    func didTapLearnMore() {
        UDVibration.buttonTap.vibrate()
        isShowingHelp = true
        view?.view.endEditing(true)
        view?.showInfoScreenWith(preset: .createBackupPassword)
    }
    
    func createPasswordButtonPressed() {
        guard let view = self.view else { return }
        guard var wallet = walletToBackUp else {
            Debugger.printFailure("Failed to get wallet to back up", critical: true)
            return
        }
        let password = view.password
        
        do {
            let backedUpWallet = try udWalletsService.backUpWallet(wallet, withPassword: password)
            try SecureHashStorage.save(password: password)
            didSaveWallet(backedUpWallet, underBackUpPassword: password)
        } catch UDWalletsService.BackUpError.alreadyBackedUp {
            wallet.hasBeenBackedUp = true
            didSaveWallet(wallet, underBackUpPassword: password)
        } catch {
            failedToBackUpWallet(error: error)
        }
    }
}
