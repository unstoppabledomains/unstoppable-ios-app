//
//  BaseBackupWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

@MainActor
protocol BackupWalletPresenterProtocol: BasePresenterProtocol {
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var progress: Double?  { get }
    var analyticsName: Analytics.ViewName { get }
    
    func didSelectBackupType(_ backupType: BackupWalletViewController.BackupType)
    func skipButtonDidPress()
}

@MainActor
class BaseBackupWalletPresenter {
    weak var view: BackupWalletViewControllerProtocol?
    
    let networkReachabilityService: NetworkReachabilityServiceProtocol?
    init(view: BackupWalletViewControllerProtocol,
         networkReachabilityService: NetworkReachabilityServiceProtocol?) {
        self.view = view
        self.networkReachabilityService = networkReachabilityService
        networkReachabilityService?.addListener(self)
    }
    
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var progress: Double? { nil }
    var analyticsName: Analytics.ViewName { .unspecified }
    func viewDidLoad() { }
    func skipButtonDidPress() { }
    func didSelectICloudOption() { }
    func didSelectRecoveryPhraseOption() { }
    func networkStatusChanged() { }
}

// MARK: - NetworkReachabilityServiceListener
extension BaseBackupWalletPresenter: NetworkReachabilityServiceListener {
    func networkStatusChanged(_ status: NetworkReachabilityStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.networkStatusChanged()
        }
    }
}

// MARK: - ProtectWalletViewPresenterProtocol
extension BaseBackupWalletPresenter: BackupWalletPresenterProtocol {
    func didSelectBackupType(_ backupType: BackupWalletViewController.BackupType) {
        UDVibration.buttonTap.vibrate()
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
