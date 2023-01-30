//
//  BaseCreateWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

protocol CreateWalletPresenterProtocol: BasePresenterProtocol {
    var analyticsName: Analytics.ViewName { get }
    
    func createVaultButtonPressed()
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
    @MainActor func viewDidLoad() { }
    @MainActor func viewDidAppear() { }
}

// MARK: - CreateWalletPresenterProtocol
extension BaseCreateWalletPresenter: CreateWalletPresenterProtocol {
    @MainActor
    func createVaultButtonPressed() {
        view?.setActivityIndicator(active: true)
        createUDWallet()
    }
}

// MARK: - Common methods
extension BaseCreateWalletPresenter {
    func createUDWallet() {
        Task {
            await view?.setNavigationGestureEnabled(false)
            do {
                let wallet = try await udWalletsService.createNewUDWallet()
                await MainActor.run {
                    view?.setNavigationGestureEnabled(true)
                    Vibration.success.vibrate()
                    walletCreated(wallet)
                }
            } catch {
                await MainActor.run {
                    Debugger.printFailure("Failed to create UD wallet: \(error)", critical: true)
                    view?.setNavigationGestureEnabled(true)
                    view?.showSimpleAlert(title: String.Constants.creationFailed.localized(),
                                          body: String.Constants.failedToCreateNewWallet.localized(error.localizedDescription))
                }
            }
        }
    }
}
