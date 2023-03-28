//
//  LoginInAppViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import Foundation

final class LoginInAppViewPresenter: LoginViewPresenter {
    private weak var loginFlowManager: LoginFlowManager?
    
    init(view: LoginViewProtocol,
         loginFlowManager: LoginFlowManager) {
        super.init(view: view)
        self.loginFlowManager = loginFlowManager
    }
    
    override func loginWithEmailAction() {
        Task {
            try? await loginFlowManager?.handle(action: .loginWithEmailAndPassword)
        }
    }
    
    override func userDidAuthorize() {
        Task {
            do {
                try await loginFlowManager?.handle(action: .authorized)
            } catch {
                authFailedWith(error: error)
            }
        }
    }
}
