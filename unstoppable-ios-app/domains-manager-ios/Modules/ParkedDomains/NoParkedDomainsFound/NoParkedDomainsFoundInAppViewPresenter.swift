//
//  NoParkedDomainsFoundInAppViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import Foundation

class NoParkedDomainsFoundInAppViewPresenter: NoParkedDomainsFoundViewPresenter {

    private weak var loginFlowManager: LoginFlowManager?
    
    init(view: NoParkedDomainsFoundViewProtocol,
         loginFlowManager: LoginFlowManager) {
        super.init(view: view)
        self.loginFlowManager = loginFlowManager
    }
    
    override func confirmButtonPressed() {
        Task {
            try? await loginFlowManager?.handle(action: .importCompleted(parkedDomains: []))
        }
    }
}
