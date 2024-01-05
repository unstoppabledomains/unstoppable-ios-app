//
//  NoParkedDomainsFoundViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2023.
//

import Foundation

@MainActor
protocol NoParkedDomainsFoundViewPresenterProtocol: BasePresenterProtocol {
    func confirmButtonPressed()
}

@MainActor
class NoParkedDomainsFoundViewPresenter {
    private(set) weak var view: NoParkedDomainsFoundViewProtocol?

    init(view: NoParkedDomainsFoundViewProtocol) {
        self.view = view
    }
    
    func confirmButtonPressed() { }
}

// MARK: - NoParkedDomainsFoundViewPresenterProtocol
extension NoParkedDomainsFoundViewPresenter: NoParkedDomainsFoundViewPresenterProtocol { }
