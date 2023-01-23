//
//  OnboardingEnterBackupPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit
import PromiseKit

final class OnboardingEnterBackupPresenter: BaseEnterBackupPresenter {
    
    private let onboardingFlowManager: OnboardingFlowManager
    
    init(view: EnterBackupViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        self.onboardingFlowManager = onboardingFlowManager
        super.init(view: view)
    }
    
    override func didTapContinueButton() {
        guard let view = self.view else { return }
        
        view.setContinueButtonEnabled(false)
        
        let password = view.password
        
        let iCloudStorage = iCloudPrivateKeyStorage()
        let iCloudWalletStorage = iCloudWalletStorage(storage: iCloudStorage)
        let wallets = iCloudWalletStorage.findWallets(password: password)
        
        when(resolved: wallets.map(
            { UDWallet.create(backedupWallet: $0, password: password) }
        )
        )
        .then { udWallets in
            self.unfold(wallets: udWallets)
        }.done { wallets in
            DispatchQueue.main.async { [weak self] in
                self?.view?.setContinueButtonEnabled(true)
            }
            let w = wallets.compactMap({ $0 })
            let unique = w.filter({!$0.isAlreadyConnected()})
            guard unique.count > 0 else {
                DispatchQueue.main.async { [weak self] in
                    self?.view?.showError(String.Constants.incorrectPassword.localized())
                }
                return
            }
            unique.forEach({ UDWalletsStorage.instance.add(newWallet: $0) })
            
            DispatchQueue.main.async { [weak self] in
                self?.didRestoreWallet()
            }
        }.catch { e in
            Debugger.printFailure("Failed to create a wallet from iCloud, error: \(e)", critical: true)
            DispatchQueue.main.async { [weak self] in
                self?.view?.setContinueButtonEnabled(true)
                self?.view?.showSimpleAlert(title: String.Constants.restoreFromICloudFailedTitle.localized(),
                                            body: String.Constants.restoreFromICloudFailedMessage.localized())
            }
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingEnterBackupPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .enterBackup }
}

// MARK: - OnboardingDataHandling
extension OnboardingEnterBackupPresenter: OnboardingDataHandling {
    func willNavigateBack() { }
}

// MARK: - Private methods
private extension OnboardingEnterBackupPresenter {
    func unfold(wallets: [Result<UDWallet>]) -> Promise<[UDWallet?]> {
        return Promise { seal in
            let r = wallets.reduce([UDWallet?]()) { res, element in
                var res0 = res
                switch element {
                case .fulfilled(let wallet): res0.append(wallet)
                case .rejected: res0.append(nil)
                }
                return res0
            }
            seal.fulfill(r)
        }
    }
    
    func didRestoreWallet() {
        onboardingFlowManager.moveToStep(.protectWallet)
    }
}
