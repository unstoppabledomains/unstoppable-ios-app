//
//  EnterValueViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.11.2022.
//

import Foundation

protocol EnterValueViewPresenterProtocol: BasePresenterProtocol {
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var progress: Double? { get }
    var analyticsName: Analytics.ViewName { get }
    
    func didTapContinueButton()
    @MainActor
    func valueDidChange(_ value: String)
}

class EnterValueViewPresenter {
    
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var progress: Double? { nil }
    var analyticsName: Analytics.ViewName { .unspecified }
    private(set) weak var view: EnterValueViewProtocol?
    private(set) var value: String?
    
    init(view: EnterValueViewProtocol, value: String?) {
        self.view = view
        self.value = value
    }
    
    func didTapContinueButton() { }
    @MainActor
    func viewDidLoad() {
        view?.setDashesProgress(progress)
        view?.setContinueButtonEnabled(false)
        if let value = self.value {
            view?.setValue(value)
        }
    }
   
    func valueValidationError() -> String? { nil }
    func isContinueButtonEnabled() -> Bool { !(value ?? "").isEmpty && valueValidationError() == nil }
    
    @MainActor
    func valueDidChange(_ value: String) {
        self.value = value
        
        let validationError = valueValidationError()
        view?.showError(validationError)
        view?.setContinueButtonEnabled(isContinueButtonEnabled())
    }
}

// MARK: - EnterValueViewPresenterProtocol
extension EnterValueViewPresenter: EnterValueViewPresenterProtocol {
}

// MARK: - Private functions
private extension EnterValueViewPresenter {

}
