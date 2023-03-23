//
//  LoginWithEmailViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.03.2023.
//

import Foundation

protocol LoginWithEmailViewPresenterProtocol: BasePresenterProtocol {
    var progress: Double? { get }
    
    func confirmButtonPressed(email: String, password: String)
}

final class LoginWithEmailViewPresenter {
    private weak var view: LoginWithEmailViewProtocol?
    
    init(view: LoginWithEmailViewProtocol) {
        self.view = view
    }
}

// MARK: - LoginWithEmailViewPresenterProtocol
extension LoginWithEmailViewPresenter: LoginWithEmailViewPresenterProtocol {
    var progress: Double? { 0.5 }
    
    func viewDidLoad() {
        Task { @MainActor in
            view?.setDashesProgress(progress)
        }
    }
    
    @MainActor
    func confirmButtonPressed(email: String, password: String) {
        Task {
            guard let nav = view?.cNavigationController else { return }
            view?.setLoadingIndicator(active: true)
            
            do {
                try await appContext.firebaseInteractionService.authorizeWith(email: email, password: password)
                let domains = try await appContext.firebaseDomainsService.loadParkedDomains()
                let displayInfo = domains.map({ FirebaseDomainDisplayInfo(firebaseDomain: $0) })
                UDRouter().showParkedDomainsFoundModuleWith(domains: displayInfo,
                                                            in: nav)
            } catch {
                Vibration.error.vibrate()
                view?.setPasswordIsIncorrect()
            }
            
            view?.setLoadingIndicator(active: false)
        }
    }
}

// MARK: - Private functions
private extension LoginWithEmailViewPresenter {

}
