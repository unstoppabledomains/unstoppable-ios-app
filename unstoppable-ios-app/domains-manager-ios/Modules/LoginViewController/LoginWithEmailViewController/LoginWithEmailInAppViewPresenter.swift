//
//  LoginWithEmailInAppViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import Foundation

final class LoginWithEmailInAppViewPresenter: LoginWithEmailViewPresenter {
    
    private weak var loginFlowManager: LoginFlowManager?
    override var progress: Double? { 0.5 }

    init(view: LoginWithEmailViewProtocol,
         loginFlowManager: LoginFlowManager) {
        super.init(view: view)
        self.loginFlowManager = loginFlowManager
    }
    
    override func didAuthorizeAction() {
        Task {
            try? await loginFlowManager?.handle(action: .authorized)
        }
    }
}
