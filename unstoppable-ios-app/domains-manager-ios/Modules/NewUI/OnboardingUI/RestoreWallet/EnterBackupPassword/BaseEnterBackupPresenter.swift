//
//  BaseEnterBackupPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

protocol EnterBackupPresenterProtocol: BasePresenterProtocol {
    var isShowingHelp: Bool { get }
    func didTapContinueButton()
    func didTapLearnMore()
}

class BaseEnterBackupPresenter {
    private(set) var isShowingHelp = false
    weak var view: EnterBackupViewControllerProtocol?
    
    init(view: EnterBackupViewControllerProtocol) {
        self.view = view
    }
    
    func viewDidLoad() { }
   
    func didTapContinueButton() { }
}

// MARK: - EnterBackupPresenterProtocol
extension BaseEnterBackupPresenter: EnterBackupPresenterProtocol {
    func didTapLearnMore() {
        isShowingHelp = true
        view?.view.endEditing(true)
        view?.showPullUpMenuWith(preset: .createBackupPassword, didCancelView: { [weak self] in
            self?.isShowingHelp = false
            self?.view?.startEditing()
        })
    }
}
