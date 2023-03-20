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
    
    func didSelectItem(_ item: LoginViewController.Item) {
        
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
}
