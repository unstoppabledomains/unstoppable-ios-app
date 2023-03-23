//
//  ParkedDomainsFoundViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import Foundation

protocol ParkedDomainsFoundViewPresenterProtocol: BasePresenterProtocol {
    var title: String { get }
    
    func didSelectItem(_ item: ParkedDomainsFoundViewController.Item)
}

final class ParkedDomainsFoundViewPresenter {
    
    private weak var view: ParkedDomainsFoundViewProtocol?
    private let domains: [FirebaseDomainDisplayInfo]
    
    var title: String {
        String.Constants.pluralWeFoundNDomains.localized(domains.count)
    }
    
    init(view: ParkedDomainsFoundViewProtocol,
         domains: [FirebaseDomainDisplayInfo]) {
        self.view = view
        self.domains = domains
    }
}

// MARK: - ParkedDomainsFoundViewPresenterProtocol
extension ParkedDomainsFoundViewPresenter: ParkedDomainsFoundViewPresenterProtocol {
    func viewDidLoad() {
        showData()
    }
    
    @MainActor
    func didSelectItem(_ item: ParkedDomainsFoundViewController.Item) {
        UDVibration.buttonTap.vibrate()
        switch item {
        case .parkedDomain:
            return
        }
    }
}

// MARK: - Private functions
private extension ParkedDomainsFoundViewPresenter {
    func showData() {
        Task {
            var snapshot = ParkedDomainsFoundSnapshot()
           
            snapshot.appendSections([.main])
            snapshot.appendItems(domains.map({ ParkedDomainsFoundViewController.Item.parkedDomain($0) }))
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
}
