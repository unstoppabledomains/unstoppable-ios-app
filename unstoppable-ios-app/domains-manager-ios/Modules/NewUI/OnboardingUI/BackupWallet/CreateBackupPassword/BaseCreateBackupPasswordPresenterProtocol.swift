//
//  BaseCreateBackupPasswordPresenterProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit
import PromiseKit

protocol CreatePasswordPresenterProtocol: BasePresenterProtocol {
    var isShowingHelp: Bool { get }
    func createPasswordButtonPressed()
    func didTapLearnMore()
}

class BaseCreateBackupPasswordPresenterProtocol {
    private(set) var isShowingHelp = false
    weak var view: CreatePasswordViewControllerProtocol?
    
    init(view: CreatePasswordViewControllerProtocol) {
        self.view = view
    }
    
    func viewDidLoad() { }
    func createPasswordButtonPressed() { }
}

// MARK: - CreatePasswordPresenterProtocol
extension BaseCreateBackupPasswordPresenterProtocol: CreatePasswordPresenterProtocol {
    func didTapLearnMore() {
        isShowingHelp = true
        view?.view.endEditing(true)
        view?.showPullUpMenuWith(preset: .createBackupPassword, didCancelView: { [weak self] in
            self?.isShowingHelp = false
            self?.view?.startEditing()
        })
    }
}
