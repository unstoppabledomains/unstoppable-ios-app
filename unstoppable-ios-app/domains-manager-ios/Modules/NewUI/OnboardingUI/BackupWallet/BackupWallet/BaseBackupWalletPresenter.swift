//
//  BaseBackupWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

protocol BackupWalletPresenterProtocol: BasePresenterProtocol {
    var numberOfWallets: Int { get }
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    
    func didSelectBackupType(_ backupType: BackupWalletViewController.BackupType)
    func skipButtonDidPress()
}

class BaseBackupWalletPresenter {
    weak var view: BackupWalletViewControllerProtocol?
    
    init(view: BackupWalletViewControllerProtocol) {
        self.view = view
    }
    
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var numberOfWallets: Int { 1 }
    func viewDidLoad() { }
    func skipButtonDidPress() { }
    func didSelectICloudOption() { }
    func didSelectRecoveryPhraseOption() { }
}

// MARK: - ProtectWalletViewPresenterProtocol
extension BaseBackupWalletPresenter: BackupWalletPresenterProtocol {
    func didSelectBackupType(_ backupType: BackupWalletViewController.BackupType) {
        switch backupType {
        case .iCloud:
            guard iCloudWalletStorage.isICloudAvailable() else {
                view?.showICloudDisabledAlert()
                return
            }
            
            didSelectICloudOption()
        case .manual:
            didSelectRecoveryPhraseOption()
        }
    }
}
