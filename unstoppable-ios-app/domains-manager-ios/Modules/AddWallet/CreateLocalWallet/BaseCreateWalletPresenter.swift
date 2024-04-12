//
//  BaseCreateWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

@MainActor
protocol CreateWalletPresenterProtocol: BasePresenterProtocol {
    var analyticsName: Analytics.ViewName { get }
    var canMoveBack: Bool { get }
    
    func createVaultButtonPressed()
}

@MainActor
class BaseCreateWalletPresenter {
    
    private let udWalletsService: UDWalletsServiceProtocol
    private var isCreatingWallet: Bool = false
    var wallet: UDWallet?
    weak var view: CreateWalletViewControllerProtocol?
    var analyticsName: Analytics.ViewName { .unspecified }
    var canMoveBack: Bool { !isCreatingWallet }

    init(view: CreateWalletViewControllerProtocol,
         udWalletsService: UDWalletsServiceProtocol) {
        self.view = view
        self.udWalletsService = udWalletsService
    }
    
    func walletCreated(_ wallet: UDWallet) {  }
    func didFailToCreateWallet() { }
    func viewDidLoad() { }
    func viewDidAppear() { }
}

// MARK: - CreateWalletPresenterProtocol
extension BaseCreateWalletPresenter: CreateWalletPresenterProtocol {
    func createVaultButtonPressed() {
        view?.setActivityIndicator(active: true)
        createUDWallet()
    }
}

// MARK: - Common methods
extension BaseCreateWalletPresenter {
    func createUDWallet() {
        guard !isCreatingWallet,
            let view else { return }
        
        Task {
            view.setNavigationGestureEnabled(false)
            isCreatingWallet = true
            do {
                let wallet = try await udWalletsService.createNewUDWallet()
                view.setNavigationGestureEnabled(true)
                appContext.analyticsService.log(event: .didAddWallet,
                                                withParameters: [.walletType : wallet.walletType.rawValue])
                Vibration.success.vibrate()
                walletCreated(wallet)
            } catch WalletError.walletsLimitExceeded(let limit) {
                view.setNavigationGestureEnabled(true)
                await appContext.pullUpViewService.showWalletsNumberLimitReachedPullUp(in: view,
                                                                                       maxNumberOfWallets: limit)
                didFailToCreateWallet()
            } catch {
                Debugger.printFailure("Failed to create UD wallet: \(error)", critical: true)
                view.setNavigationGestureEnabled(true)
                view.showSimpleAlert(title: String.Constants.creationFailed.localized(),
                                      body: String.Constants.failedToCreateNewWallet.localized(error.localizedDescription))
                didFailToCreateWallet()
            }
            isCreatingWallet = false
        }
    }
}
