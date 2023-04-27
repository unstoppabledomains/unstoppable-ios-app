//
//  EnterEmailValuePresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.11.2022.
//

import Foundation

typealias EnterEmailValueCallback = (String)->()

final class EnterEmailValuePresenter: EnterValueViewPresenter, UserDataValidator {
    
    override var analyticsName: Analytics.ViewName { .addEmail }
    private let email: String
    var enteredEmailValueCallback: EnterEmailValueCallback?
    
    init(view: EnterValueViewProtocol,
         email: String?,
         enteredEmailValueCallback: @escaping EnterEmailValueCallback) {
        self.email = email ?? ""
        super.init(view: view, value: email)
        self.enteredEmailValueCallback = enteredEmailValueCallback
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.set(title: String.Constants.addN.localized(String.Constants.email.localized().lowercased()),
                  icon: .mailIcon24,
                  tintColor: .foregroundSecondary)
        view?.setPlaceholder(String.Constants.addYourEmailAddress.localized(), style: .default)
        view?.setKeyboardType(.emailAddress)
    }
    
    override func isContinueButtonEnabled() -> Bool {
        if !email.isEmpty,
           value?.isEmpty == true {
            return true
        }
        return super.isContinueButtonEnabled()
    }
    
    override func valueValidationError() -> String? {
        guard let email = self.value else { return nil }
        
        if email.trimmedSpaces.isEmpty {
            return nil
        }
        
        let errorMessage = String.Constants.enterValidEmailAddress.localized()
        let emailValidationResult = isEmailValid(email)
        
        switch emailValidationResult {
        case .success:
            if email.contains("@ud.me") {
                return errorMessage
            }
            return nil
        case .failure:
            return errorMessage
        }
    }
    
    override func didTapContinueButton() {
        guard let email = self.value else { return }
        
        Task { @MainActor in
            enteredEmailValueCallback?(email)
            view?.cNavigationController?.popViewController(animated: true)
        }
    }
}
