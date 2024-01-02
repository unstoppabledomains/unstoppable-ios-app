//
//  EnterEmailViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.05.2022.
//

import UIKit

@MainActor
protocol EnterEmailViewPresenterProtocol: BasePresenterProtocol {
    var progress: Double? { get }
    func continueButtonPressed()
}

@MainActor
class EnterEmailViewPresenter {
    
    private(set) weak var view: EnterEmailViewProtocol?
    private let userDataService: UserDataServiceProtocol
    private(set) var preFilledEmail: String?
    var progress: Double? { nil }

    init(view: EnterEmailViewProtocol,
         userDataService: UserDataServiceProtocol,
         preFilledEmail: String?) {
        self.view = view
        self.userDataService = userDataService
        self.preFilledEmail = preFilledEmail
    }
    
    func viewDidLoad() {
        if let preFilledEmail = preFilledEmail {
            view?.setEmail(preFilledEmail)
        }
    }
    func viewWillAppear() { }
    func didSendVerificationCode(on email: String) { }
}

// MARK: - EnterEmailViewPresenterProtocol
extension EnterEmailViewPresenter: EnterEmailViewPresenterProtocol {
    func continueButtonPressed() {
        Task {
            guard let email = view?.email else { return }
            
            view?.setLoadingIndicator(active: true)
            do {
                try await userDataService.sendUserEmailVerificationCode(to: email)
                view?.setLoadingIndicator(active: false)
                didSendVerificationCode(on: email)
            } catch {
                view?.setLoadingIndicator(active: false)
                if let networkError = error as? NetworkLayerError,
                   case .badResponseOrStatusCode(_, let message) = networkError,
                   let message,
                   let specificError = SpecificError.allCases.first(where: { message.contains($0.rawValue) }) {
                    switch specificError {
                    case .unableToCreateAccount:
                        showUnableToCreateAccountAlert()
                    case .unableToFindAccount:
                        showAccountNotFoundAlert()
                    }
                } else {
                    view?.showAlertWith(error: error, handler: nil)
                }
            }
        }
    }
}

// MARK: - Private functions
private extension EnterEmailViewPresenter {
    @MainActor
    func showUnableToCreateAccountAlert() {
        let alert = UIAlertController(title: String.Constants.unableToCreateAccount.localized(),
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        alert.addAction(UIAlertAction(title: String.Constants.learnMore.localized(), style: .default, handler: { [weak self] _ in
            self?.view?.openLink(.unableToCreateAccountTutorial)
        }))
        
        view?.present(alert, animated: true)
    }
    
    @MainActor
    func showAccountNotFoundAlert() {
        view?.showSimpleAlert(title: String.Constants.unableToFindAccountTitle.localized(),
                              body: String.Constants.unableToFindAccountMessage.localized())
    }
}

// MARK: - Private methods
private extension EnterEmailViewPresenter {
    enum SpecificError: String, CaseIterable {
        case unableToCreateAccount = "Can't create user with following email"
        case unableToFindAccount = "Can't load user with email:"
    }
}
