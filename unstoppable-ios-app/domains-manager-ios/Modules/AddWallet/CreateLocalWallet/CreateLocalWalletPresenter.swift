//
//  CreateLocalWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

// Create wallet not dismissable

final class CreateLocalWalletPresenter: BaseCreateWalletPresenter {
    private weak var addWalletFlowManager: AddWalletFlowManager?
    override var analyticsName: Analytics.ViewName { .createNewUDVault }
    
    init(view: CreateWalletViewControllerProtocol,
         addWalletFlowManager: AddWalletFlowManager,
         udWalletsService: UDWalletsServiceProtocol) {
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view,
                   udWalletsService: udWalletsService)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.setActivityIndicator(active: true)
        view?.setStyle(.progressIndicator)
    }
    
    override func viewDidAppear() {
        if wallet == nil {
            createUDWallet()
        }
    }
    
    override func walletCreated(_ wallet: UDWallet) {
        addWalletFlowManager?.wallet = wallet
        self.addWalletFlowManager?.moveToStep(.backupWallet)
    }
}

