//
//  CreateLocalWalletRecoveryWordsPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

final class CreateLocalWalletRecoveryWordsPresenter: BaseConfirmRecoveryWordsPresenter {
    
    private weak var addWalletFlowManager: AddWalletFlowManager?
    override var wallet: UDWallet? { addWalletFlowManager?.wallet }
    override var analyticsName: Analytics.ViewName { .createWalletConfirmRecoveryWords }

    init(view: ConfirmWordsViewControllerProtocol,
         addWalletFlowManager: AddWalletFlowManager) {
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.setDashesProgress(nil)
    }
    
    override func didConfirmWords() {
        addWalletFlowManager?.didFinishAddWalletFlow()
    }
}
