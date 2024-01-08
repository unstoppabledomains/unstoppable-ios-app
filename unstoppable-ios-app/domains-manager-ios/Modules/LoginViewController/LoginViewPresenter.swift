//
//  LoginViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2023.
//

import Foundation

@MainActor
protocol LoginViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: LoginViewController.Item)
}

@MainActor
class LoginViewPresenter: NSObject, ViewAnalyticsLogger {
    private(set) weak var view: LoginViewProtocol?
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }

    init(view: LoginViewProtocol) {
        super.init()
        self.view = view
    }
    
    func viewDidLoad() {
        showData()
        view?.setDashesProgress(0.25)
    }
    func loginWithEmailAction() { }
    func userDidAuthorize(provider: LoginProvider) { }
    
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
    @MainActor
    func didSelectItem(_ item: LoginViewController.Item) {
        UDVibration.buttonTap.vibrate()
        switch item {
        case .loginWith(let provider):
            logAnalytic(event: .websiteLoginOptionSelected,
                        parameters: [.websiteLoginOption: provider.rawValue])
            switch provider {
            case .email:
                loginWithEmailAction()
            case .google:
                loginWithGoogle()
            case .twitter:
                loginWithTwitter()
            case .apple:
                loginWithApple()
            }
        }
    }
}

// MARK: - Private functions
private extension LoginViewPresenter {
    func showData() {
        var snapshot = LoginSnapshot()
        
        snapshot.appendSections([.main])
        snapshot.appendItems([.loginWith(provider: .email),
                              .loginWith(provider: .google),
                              .loginWith(provider: .twitter),
                              .loginWith(provider: .apple)])
        
        view?.applySnapshot(snapshot, animated: true)
    }
    
    func loginWithGoogle()  {
        Task {
            guard let window = SceneDelegate.shared?.window else { return }
    
            do {
                try await appContext.firebaseParkedDomainsAuthenticationService.authorizeWithGoogle(in: window)
                userDidAuthorize(provider: .google)
            } catch {
                authFailedWith(error: error)
            }
        }
    }
    
    func loginWithTwitter() {
        Task {
            guard let view else { return }
            
            do {
                try await appContext.firebaseParkedDomainsAuthenticationService.authorizeWithTwitter(in: view)
                userDidAuthorize(provider: .twitter)
            } catch {
                authFailedWith(error: error)
            }
        }
    }
    
    func loginWithApple() {
        Task {            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

import AuthenticationServices

// MARK: - Open methods
extension LoginViewPresenter: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        SceneDelegate.shared!.window!
    }
    nonisolated
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            await userDidAuthorize(provider: .apple)
        }
    }
    nonisolated
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task {
            if let error = error as? ASAuthorizationError {
                switch error.code {
                case .canceled:
                    return
                default:
                    await authFailedWith(error: error)
                }
            } else {
                await authFailedWith(error: error)
            }
        }
    }
}
