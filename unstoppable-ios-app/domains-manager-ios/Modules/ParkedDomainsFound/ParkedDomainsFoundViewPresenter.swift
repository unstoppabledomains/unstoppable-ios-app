//
//  ParkedDomainsFoundViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import Foundation

protocol ParkedDomainsFoundViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: ParkedDomainsFoundViewController.Item)
}

final class ParkedDomainsFoundViewPresenter {
    
    private weak var view: ParkedDomainsFoundViewProtocol?
    private let domains: [FirebaseDomain]
    
    init(view: ParkedDomainsFoundViewProtocol,
         domains: [FirebaseDomain]) {
        self.view = view
        self.domains = domains
    }
}

// MARK: - ParkedDomainsFoundViewPresenterProtocol
extension ParkedDomainsFoundViewPresenter: ParkedDomainsFoundViewPresenterProtocol {
    func viewDidLoad() {
        showData()
    }
    
    func didSelectItem(_ item: ParkedDomainsFoundViewController.Item) {
        
    }
}

// MARK: - Private functions
private extension ParkedDomainsFoundViewPresenter {
    func showData() {
        Task {
            var snapshot = ParkedDomainsFoundSnapshot()
           
            // Fill snapshot
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
}
