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

class LoginViewPresenter {
    private(set) weak var view: LoginViewProtocol?

    init(view: LoginViewProtocol) {
        self.view = view
    }
    @MainActor
    func loginWithEmailAction() { }
    @MainActor
    func userDidAuthorize() { }
    
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

// MARK: - LoginViewPresenterProtocol
extension LoginViewPresenter: LoginViewPresenterProtocol {
    func viewDidLoad() {
        showData()
        view?.setDashesProgress(0.25)
    }
    
    @MainActor
    func didSelectItem(_ item: LoginViewController.Item) {
        UDVibration.buttonTap.vibrate()
        switch item {
        case .loginWith(let provider):
            switch provider {
            case .email:
                loginWithEmailAction()
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
    
    func loginWithGoogle()  {
        Task {
            guard let view else { return }
    
            do {
                try await appContext.firebaseInteractionService.authorizeWithGoogle(in: view)
                await userDidAuthorize()
            } catch {
                await authFailedWith(error: error)
            }
        }
    }
    
    func loginWithTwitter() {
        Task {
            guard let view else { return }
            
            do {
                try await appContext.firebaseInteractionService.authorizeWithTwitter(in: view)
                await userDidAuthorize()
            } catch {
                await authFailedWith(error: error)
            }
        }
    }
}
