//
//  LoadingParkedDomainsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2023.
//

import Foundation

@MainActor
protocol LoadingParkedDomainsViewPresenterProtocol: BasePresenterProtocol {

}

@MainActor
class LoadingParkedDomainsViewPresenter {
    private(set) weak var view: LoadingParkedDomainsViewProtocol?

    init(view: LoadingParkedDomainsViewProtocol) {
        self.view = view
    }
    
    func viewWillAppear() { }
}

// MARK: - LoadingParkedDomainsViewPresenterProtocol
extension LoadingParkedDomainsViewPresenter: LoadingParkedDomainsViewPresenterProtocol {
    
}

// MARK: - Private functions
private extension LoadingParkedDomainsViewPresenter {

}

