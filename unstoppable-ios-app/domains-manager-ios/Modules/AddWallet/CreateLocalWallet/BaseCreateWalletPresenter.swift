//
//  BaseCreateWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

protocol CreateWalletPresenterProtocol: BasePresenterProtocol {
    var analyticsName: Analytics.ViewName { get }
}

class BaseCreateWalletPresenter {
    
    private let udWalletsService: UDWalletsServiceProtocol
    var wallet: UDWallet?
    weak var view: CreateWalletViewControllerProtocol?
    var analyticsName: Analytics.ViewName { .unspecified }
    
    init(view: CreateWalletViewControllerProtocol,
         udWalletsService: UDWalletsServiceProtocol) {
        self.view = view
        self.udWalletsService = udWalletsService
    }
    
    func walletCreated(_ wallet: UDWallet) {  }
}

// MARK: - CreateWalletPresenterProtocol
extension BaseCreateWalletPresenter: CreateWalletPresenterProtocol {
    func viewDidLoad() {
        view?.setActivityIndicator(active: true)
    }
    
    func viewDidAppear() {
        if wallet == nil {
            createUDWallet()
        }
    }
}

// MARK: - Private methods
private extension BaseCreateWalletPresenter {
    func createUDWallet() {
        Task {
            do {
                let wallet = try await udWalletsService.createNewUDWallet()
                await MainActor.run {
                    Vibration.success.vibrate()
                    walletCreated(wallet)
                }
            } catch {
                await MainActor.run {
                    Debugger.printFailure("Failed to create UD wallet: \(error)", critical: true)
                    view?.showSimpleAlert(title: String.Constants.creationFailed.localized(),
                                               body: String.Constants.failedToCreateNewWallet.localized(error.localizedDescription))
                }
            }
        }
    }
}
