//
//  CreateBackupPasswordCreatedLocalWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import Foundation

final class CreateBackupPasswordCreatedLocalWalletPresenter: BaseCreateBackupPasswordPresenterProtocol {
    private let addWalletFlowManager: AddWalletFlowManager
    
    init(view: CreatePasswordViewControllerProtocol,
         addWalletFlowManager: AddWalletFlowManager) {
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        view?.setDashesProgress(nil)
        view?.setDistanceToDashesView(-28)
    }
    
    override func createPasswordButtonPressed() {
        guard let view = self.view else { return }
        
        let password = view.password
        addWalletFlowManager.moveToStep(.recoveryPhraseConfirmed(password: password))
    }
}
