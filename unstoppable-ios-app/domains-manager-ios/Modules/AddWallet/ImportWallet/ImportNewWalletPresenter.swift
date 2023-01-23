//
//  ImportNewWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.05.2022.
//

import UIKit

final class ImportNewWalletPresenter: BaseAddWalletPresenter {
    
    typealias WalletImportedCallback = ((UDWallet)->())
    
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .importNewWallet }
    
    private weak var addWalletFlowManager: AddWalletFlowManager?

    init(view: AddWalletViewControllerProtocol,
         walletType: RestorationWalletType,
         udWalletsService: UDWalletsServiceProtocol,
         addWalletFlowManager: AddWalletFlowManager) {
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view, walletType: walletType, udWalletsService: udWalletsService)
    }
    
    override func didCreateWallet(wallet: UDWallet) {
        super.didCreateWallet(wallet: wallet)
        
        addWalletFlowManager?.wallet = wallet
        if iCloudWalletStorage.isICloudAvailable() {
            addWalletFlowManager?.moveToStep(.backupWallet)
        } else {
            addWalletFlowManager?.didFinishAddWalletFlow()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.setDashesProgress(nil)
    }
}
