//
//  CreateLocalWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

// Create wallet not dismissable

final class CreateLocalWalletPresenter: BaseCreateWalletPresenter {
    private let addWalletFlowManager: AddWalletFlowManager
    private var wallet: UDWallet?
    
    init(view: CreateWalletViewControllerProtocol,
         addWalletFlowManager: AddWalletFlowManager) {
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view)
    }
    
    override func walletCreated(_ wallet: UDWallet) {
        addWalletFlowManager.wallet = wallet
        self.addWalletFlowManager.moveToStep(.backupWallet)
    }
}

