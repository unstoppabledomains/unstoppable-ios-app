//
//  LoadingParkedDomainsInAppViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import Foundation

final class LoadingParkedDomainsInAppViewPresenter: LoadingParkedDomainsViewPresenter {
    private weak var view: LoadingParkedDomainsViewProtocol?
    private weak var loginFlowManager: LoginFlowManager?
    
    init(view: LoadingParkedDomainsViewProtocol,
         loginFlowManager: LoginFlowManager) {
        super.init(view: view)
        self.loginFlowManager = loginFlowManager
    }
}
