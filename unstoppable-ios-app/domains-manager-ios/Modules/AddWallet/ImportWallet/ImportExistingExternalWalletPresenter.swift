//
//  ImportExistingExternalWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.11.2022.
//

import UIKit

final class ImportExistingExternalWalletPresenter: BaseAddWalletPresenter {
    
    typealias WalletImportedCallback = ((UDWallet)->())
    
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .importExistingExternalWallet }

    private let externalWalletInfo: WalletDisplayInfo
    private let walletImportedCallback: WalletImportedCallback
    
    init(view: AddWalletViewControllerProtocol,
         walletType: RestorationWalletType,
         udWalletsService: UDWalletsServiceProtocol,
         externalWalletInfo: WalletDisplayInfo,
         walletImportedCallback: @escaping WalletImportedCallback) {
        self.externalWalletInfo = externalWalletInfo
        self.walletImportedCallback = walletImportedCallback
        super.init(view: view, walletType: walletType, udWalletsService: udWalletsService)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.setDashesProgress(nil)
        view?.setWith(externalWalletIcon: externalWalletInfo.source.displayIcon, address: externalWalletInfo.address)
    }
    
    override func didCreateWallet(wallet: UDWallet) {
        super.didCreateWallet(wallet: wallet)
        
        walletImportedCallback(wallet)
    }
    
    @MainActor
    override func shouldImport(wallet: UDWalletWithPrivateSeed) -> Bool {
        guard wallet.udWallet.address == externalWalletInfo.address else {
            view?.setInputState(.error(text: "Wrong recovery phrase for this wallet"))
            return false
        }
        
        return true
    }
}
