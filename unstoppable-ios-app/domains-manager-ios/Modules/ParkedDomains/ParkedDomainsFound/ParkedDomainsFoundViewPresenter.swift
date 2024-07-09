//
//  ParkedDomainsFoundViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import Foundation

protocol ParkedDomainsFoundViewPresenterProtocol: BasePresenterProtocol {
    var title: String { get }
    var progress: Double? { get }

    func importButtonPressed()
}

class ParkedDomainsFoundViewPresenter {
    
    private(set) weak var view: ParkedDomainsFoundViewProtocol?
    let domains: [FirebaseDomainDisplayInfo]

    var title: String {
        String.Constants.pluralWeFoundNDomains.localized(domains.count, domains.count)
    }
    var progress: Double? { 1 }

    init(view: ParkedDomainsFoundViewProtocol,
         domains: [FirebaseDomainDisplayInfo]) {
        self.view = view
        self.domains = domains
    }
    
    @MainActor
    func importButtonPressed() { }
}

// MARK: - ParkedDomainsFoundViewPresenterProtocol
extension ParkedDomainsFoundViewPresenter: ParkedDomainsFoundViewPresenterProtocol {
    func viewDidLoad() {
        Task { @MainActor in
            view?.setWith(email: webUser?.email ?? "", numberOfDomainsFound: domains.count)
            view?.setDashesProgress(progress)
        }
    }
}

// MARK: - Private methods
private extension ParkedDomainsFoundViewPresenter {
    var webUser: FirebaseUser? {
        for profile in appContext.userProfilesService.profiles {
            if case .webAccount(let firebaseUser) = profile {
                return firebaseUser
            }
        }
        return nil
    }
}
