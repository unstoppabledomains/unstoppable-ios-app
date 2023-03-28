//
//  NoParkedDomainsFoundViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2023.
//

import Foundation

protocol NoParkedDomainsFoundViewPresenterProtocol: BasePresenterProtocol {
    func confirmButtonPressed()
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
    func confirmButtonPressed() {
        Task {
            try? await loginFlowManager?.handle(action: .importCompleted(parkedDomains: []))
        }
    }
}

// MARK: - Private functions
private extension NoParkedDomainsFoundViewPresenter {

}
