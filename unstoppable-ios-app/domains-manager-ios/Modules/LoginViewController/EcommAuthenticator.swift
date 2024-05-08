//
//  EcommAuthenticator.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2024.
//

import Foundation
import AuthenticationServices

@MainActor
final class EcommAuthenticator: NSObject {
    
    enum AuthResult {
        case authorised(LoginProvider)
        case failed(Error)
    }
    
    typealias ResultCallback = (AuthResult)->()
    
    private var resultCallback: ResultCallback?
    
    func loginWithGoogle(resultCallback: @escaping ResultCallback) {
        startWith(resultCallback: resultCallback)
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
    
    func loginWithTwitter(resultCallback: @escaping ResultCallback) {
        startWith(resultCallback: resultCallback)
        Task {
            guard let view = appContext.coreAppCoordinator.topVC else { return }
            
            do {
                try await appContext.firebaseParkedDomainsAuthenticationService.authorizeWithTwitter(in: view)
                userDidAuthorize(provider: .twitter)
            } catch {
                authFailedWith(error: error)
            }
        }
    }
    
    func loginWithApple(resultCallback: @escaping ResultCallback) {
        startWith(resultCallback: resultCallback)
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

// MARK: - Private methods
private extension EcommAuthenticator {
    func startWith(resultCallback: @escaping ResultCallback) {
        self.resultCallback = resultCallback
    }
    
    func userDidAuthorize(provider: LoginProvider) {
        didAuthWithResult(.authorised(provider))
    }
    
    func authFailedWith(error: Error) {
        if let firebaseError = error as? FirebaseAuthError,
           case .userCancelled = firebaseError {
            return // Ignore case when user cancelled auth
        } else {
            didAuthWithResult(.failed(error))
        }
    }
    
    func didAuthWithResult(_ result: AuthResult) {
        resultCallback?(result)
        resultCallback = nil
    }
}

// MARK: - Open methods
extension EcommAuthenticator: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
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

