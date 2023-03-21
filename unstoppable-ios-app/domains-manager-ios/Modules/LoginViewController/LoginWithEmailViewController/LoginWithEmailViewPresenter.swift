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
    var progress: Double? { 0.25 }
    
    @MainActor
    func confirmButtonPressed(email: String, password: String) {
        Task {
            view?.setLoadingIndicator(active: true)
            
            do {
                try await FirebaseInteractionService.shared.authorizeWith(email: email, password: password)
            } catch {
                view?.setPasswordIsIncorrect()
            }
            
            view?.setLoadingIndicator(active: false)
        }
    }
}

// MARK: - Private functions
private extension LoginWithEmailViewPresenter {

}
