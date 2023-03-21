//
//  LoginViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2023.
//

import Foundation

protocol LoginViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: LoginViewController.Item)
}

final class LoginViewPresenter {
    private weak var view: LoginViewProtocol?
    
    init(view: LoginViewProtocol) {
        self.view = view
    }
}

// MARK: - LoginViewPresenterProtocol
extension LoginViewPresenter: LoginViewPresenterProtocol {
    func viewDidLoad() {
        showData()
    }
    
    @MainActor
    func didSelectItem(_ item: LoginViewController.Item) {
        UDVibration.buttonTap.vibrate()
        switch item {
        case .loginWith(let provider):
            switch provider {
            case .email:
                loginWithEmail()
            case .google:
                loginWithGoogle()
            case .twitter:
                loginWithTwitter()
            }
        }
    }
}

// MARK: - Private functions
private extension LoginViewPresenter {
    func showData() {
        Task {
            var snapshot = LoginSnapshot()
           
            snapshot.appendSections([.main])
            snapshot.appendItems([.loginWith(provider: .email),
                                  .loginWith(provider: .google),
                                  .loginWith(provider: .twitter)])
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
    
    @MainActor
    func loginWithEmail() {
        guard let view,
            let nav = view.cNavigationController else { return }
        
        UDRouter().showLoginWithEmailScreen(in: nav)
    }
    
    func loginWithGoogle()  {
        Task {
            guard let view else { return }
    
            do {
                try await FirebaseInteractionService.shared.authorizeWithGoogle(in: view)
                await userAuthorized()
            } catch {
                await authFailedWith(error: error)
            }
        }
    }
    
    func loginWithTwitter() {
        Task {
            guard let view else { return }
            
            do {
                try await FirebaseInteractionService.shared.authorizeWithTwitter(in: view)
                await userAuthorized()
            } catch {
                await authFailedWith(error: error)
            }
        }
    }
    
    @MainActor
    func userAuthorized() {
        view?.cNavigationController?.popViewController(animated: true)
    }
    
    @MainActor
    func authFailedWith(error: Error) {
        if let firebaseError = error as? FirebaseAuthError,
           case .userCancelled = firebaseError {
            return // Ignore case when user cancelled auth
        } else {
            view?.showAlertWith(error: error, handler: nil)
        }
    }
}
