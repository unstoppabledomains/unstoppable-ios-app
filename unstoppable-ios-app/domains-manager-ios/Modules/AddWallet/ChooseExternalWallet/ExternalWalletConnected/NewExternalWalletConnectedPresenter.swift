//
//  NewExternalWalletConnectedPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.05.2022.
//

import UIKit

final class NewExternalWalletConnectedPresenter: BaseExternalWalletConnectedPresenter {
    
    private weak var addWalletFlowManager: AddWalletFlowManager?
    override var wallet: UDWallet? { addWalletFlowManager?.wallet }
    override var analyticsName: Analytics.ViewName { .newExternalWalletConnected }

    init(view: WalletConnectedViewControllerProtocol,
         addWalletFlowManager: AddWalletFlowManager) {
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.setPrimaryButtonTitle(String.Constants.doneButtonTitle.localized())
    }
    
    override func didTapContinueButton() {
        addWalletFlowManager?.didFinishAddWalletFlow()
    }
}
