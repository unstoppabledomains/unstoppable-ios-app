//
//  BaseEnterBackupPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

protocol EnterBackupPresenterProtocol: BasePresenterProtocol {
    var isShowingHelp: Bool { get }
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var progress: Double? { get }
    var analyticsName: Analytics.ViewName { get }

    func didTapContinueButton()
    func didTapLearnMore()
}

class EnterBackupBasePresenter {
    private(set) var isShowingHelp = false
    weak var view: EnterBackupViewControllerProtocol?
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var progress: Double? { nil }
    var analyticsName: Analytics.ViewName { .unspecified }

    init(view: EnterBackupViewControllerProtocol) {
        self.view = view
    }
    
    func viewDidLoad() { }
    func didTapContinueButton() { }
    
}

// MARK: - EnterBackupPresenterProtocol
extension EnterBackupBasePresenter: EnterBackupPresenterProtocol {
    func didTapLearnMore() {
        UDVibration.buttonTap.vibrate()
        isShowingHelp = true
        view?.view.endEditing(true)
        view?.showInfoScreenWith(preset: .createBackupPassword, dismissCallback: { [weak self] in
            self?.isShowingHelp = false
            self?.view?.startEditing()
        })
    }
}
