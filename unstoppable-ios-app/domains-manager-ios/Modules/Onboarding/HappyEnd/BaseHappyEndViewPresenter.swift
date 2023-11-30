//
//  HappyEndViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.11.2023.
//

import Foundation

@MainActor
protocol HappyEndViewPresenterProtocol: BasePresenterProtocol {
    var analyticsName: Analytics.ViewName { get }
    
    func actionButtonPressed()
    func agreementSwitchValueChanged(isOn: Bool)
}

@MainActor
class BaseHappyEndViewPresenter {
    
    private(set) weak var view: HappyEndViewControllerProtocol?
    var analyticsName: Analytics.ViewName { .unspecified }
    private(set) var isAgreementAccepted = false
    
    init(view: HappyEndViewControllerProtocol) {
        self.view = view
    }
    
    func viewDidLoad() { }
    func actionButtonPressed() { }
    func agreementSwitchValueChanged(isOn: Bool) {
        isAgreementAccepted = isOn
        view?.setActionButtonEnabled(isAgreementAccepted)
    }
}

extension BaseHappyEndViewPresenter: HappyEndViewPresenterProtocol {
    
}
