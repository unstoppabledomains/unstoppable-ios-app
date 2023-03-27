//
//  NoParkedDomainsFoundViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2023.
//

import Foundation

protocol NoParkedDomainsFoundViewPresenterProtocol: BasePresenterProtocol {

}

final class NoParkedDomainsFoundViewPresenter {
    private weak var view: NoParkedDomainsFoundViewProtocol?
    private weak var loginFlowManager: LoginFlowManager?

    init(view: NoParkedDomainsFoundViewProtocol,
         loginFlowManager: LoginFlowManager) {
        self.view = view
        self.loginFlowManager = loginFlowManager
    }
}

// MARK: - NoParkedDomainsFoundViewPresenterProtocol
extension NoParkedDomainsFoundViewPresenter: NoParkedDomainsFoundViewPresenterProtocol {
    
}

// MARK: - Private functions
private extension NoParkedDomainsFoundViewPresenter {

}
