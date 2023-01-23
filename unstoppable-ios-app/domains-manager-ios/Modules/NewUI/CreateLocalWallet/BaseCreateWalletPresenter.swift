//
//  BaseCreateWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit
import PromiseKit

protocol CreateWalletPresenterProtocol: BasePresenterProtocol {
}

class BaseCreateWalletPresenter {
    private var wallet: UDWallet?
    weak var view: CreateWalletViewControllerProtocol?
    
    init(view: CreateWalletViewControllerProtocol) {
        self.view = view
    }
    
    func walletCreated(_ wallet: UDWallet) {  }
}

// MARK: - CreateWalletPresenterProtocol
extension BaseCreateWalletPresenter: CreateWalletPresenterProtocol {
    func viewDidLoad() {
        view?.setActivityIndicator(active: true)
    }
    
    func viewDidAppear() {
        createWallet()
    }
}

// MARK: - Private methods
private extension BaseCreateWalletPresenter {
    func createWallet() {
        let namePrefix = "Wallet"
        let newName = UDWalletsStorage.instance.getLowestIndexedName(startingWith: namePrefix)
        
        let waitAtLeast = after(seconds: 3)

        UDWallet.create(aliasName: newName)
            .then { udWallet -> Guarantee<Void> in
                self.wallet = udWallet
                return waitAtLeast }
            .done {  self.didCreateWallet() }
            .catch { error in
                Debugger.printFailure("Failed to create HD wallet: \(error)", critical: true)
                self.view?.showSimpleAlert(title: String.Constants.creationFailed.localized(),
                                           body: String.Constants.failedToCreateNewWallet.localized(error.localizedDescription))
            }
    }
    
    func didCreateWallet() {
        guard let wallet = self.wallet else {
            Debugger.printFailure("Attempt to save a nil wallet", critical: true)
            return }
        
        store(wallet: wallet)
        
        DispatchQueue.main.async { [weak self] in
            self?.walletCreated(wallet)
        }
    }
    
    private func store(wallet: UDWallet) {
        UDWalletsStorage.instance.add(newWallet: wallet)
    }
}
