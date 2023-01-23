//
//  CreateLocalWalletRecoveryWordsPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

final class CreateLocalWalletRecoveryWordsPresenter: BaseConfirmRecoveryWordsPresenter {
    
    private let addWalletFlowManager: AddWalletFlowManager
    override var wallet: UDWallet? { addWalletFlowManager.wallet }

    init(view: ConfirmWordsViewControllerProtocol,
         addWalletFlowManager: AddWalletFlowManager) {
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.setDashesProgress(nil)
        view?.setDistanceToDashesView(UIDevice.isDeviceWithNotch ? 0 : 28)
    }
    
    override func didConfirmWords() {
        addWalletFlowManager.didFinishCreateWalletFlow()
    }
}
