//
//  EnterEmailViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.05.2022.
//

import Foundation

protocol EnterEmailViewPresenterProtocol: BasePresenterProtocol {
    var progress: Double? { get }
    func continueButtonPressed()
}

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
            Task { await view?.setEmail(preFilledEmail) }
        }
    }
    func viewWillAppear() { }
    func didSendVerificationCode(on email: String) { }
}

// MARK: - EnterEmailViewPresenterProtocol
extension EnterEmailViewPresenter: EnterEmailViewPresenterProtocol {
    func continueButtonPressed() {
        Task {
            guard let email = await view?.email else { return }
            
            await view?.setLoadingIndicator(active: true)
            do {
                try await userDataService.sendUserEmailVerificationCode(to: email)
                await view?.setLoadingIndicator(active: false)
                didSendVerificationCode(on: email)
            } catch {
                await MainActor.run {
                    view?.setLoadingIndicator(active: false)
                    view?.showAlertWith(error: error, handler: nil)
                }
            }
        }
    }
}

// MARK: - Private functions
private extension EnterEmailViewPresenter {
 
    

}
