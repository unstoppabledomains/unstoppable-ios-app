//
//  LoginWithEmailViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.03.2023.
//

import Foundation

@MainActor
protocol LoginWithEmailViewPresenterProtocol: BasePresenterProtocol {
    var progress: Double? { get }
    
    func confirmButtonPressed(email: String, password: String)
}

@MainActor
class LoginWithEmailViewPresenter {
    private(set) weak var view: LoginWithEmailViewProtocol?
    var progress: Double? { nil }

    init(view: LoginWithEmailViewProtocol) {
        self.view = view
    }
    
    func didAuthorizeAction() { }
}

// MARK: - LoginWithEmailViewPresenterProtocol
extension LoginWithEmailViewPresenter: LoginWithEmailViewPresenterProtocol {
    
    func viewDidLoad() {
        Task { @MainActor in
            view?.setDashesProgress(progress)
        }
    }
    
    @MainActor
    func confirmButtonPressed(email: String, password: String) {
        Task {
            view?.setLoadingIndicator(active: true)
            
            do {
                try await appContext.firebaseParkedDomainsAuthenticationService.authorizeWith(email: email, password: password)
                didAuthorizeAction()
            } catch {
                Vibration.error.vibrate()
                view?.setPasswordIsIncorrect()
            }
            
            view?.setLoadingIndicator(active: false)
        }
    }
}
