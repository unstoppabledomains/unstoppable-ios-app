//
//  LoadingParkedDomainsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2023.
//

import Foundation

protocol LoadingParkedDomainsViewPresenterProtocol: BasePresenterProtocol {

}

final class LoadingParkedDomainsViewPresenter {
    private weak var view: LoadingParkedDomainsViewProtocol?
    private weak var loginFlowManager: LoginFlowManager?

    init(view: LoadingParkedDomainsViewProtocol,
         loginFlowManager: LoginFlowManager) {
        self.view = view
        self.loginFlowManager = loginFlowManager
    }
}

// MARK: - LoadingParkedDomainsViewPresenterProtocol
extension LoadingParkedDomainsViewPresenter: LoadingParkedDomainsViewPresenterProtocol {
    
}

// MARK: - Private functions
private extension LoadingParkedDomainsViewPresenter {

}
