//
//  BaseAddWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

@MainActor
protocol AddWalletPresenterProtocol: BasePresenterProtocol {
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var progress: Double? { get }
    var analyticsName: Analytics.ViewName { get }

    func didChangeInput()
    func didTapContinueButton()
    func didTapPasteButton()
}

class BaseAddWalletPresenter {
    
    let walletType: RestorationWalletType
    weak var view: AddWalletViewControllerProtocol?
    private let udWalletsService: UDWalletsServiceProtocol
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var validationTask: Task<UDWalletWithPrivateSeed?, Error>?
    var progress: Double? { nil }
    var analyticsName: Analytics.ViewName { .unspecified }

    init(view: AddWalletViewControllerProtocol,
         walletType: RestorationWalletType,
         udWalletsService: UDWalletsServiceProtocol) {
        self.view = view
        self.walletType = walletType
        self.udWalletsService = udWalletsService
    }
    @MainActor
    func viewDidLoad() {
        view?.setHint(walletType.hintPhrase)
    }
    @MainActor
    func didCreateWallet(wallet: UDWallet) {
        Vibration.success.vibrate()
    }
    @MainActor
    func shouldImport(wallet: UDWalletWithPrivateSeed) -> Bool { true }
}

// MARK: - AddWalletPresenterProtocol
extension BaseAddWalletPresenter: AddWalletPresenterProtocol {
    func viewWillDisappear() {
        cancelValidationTask()
    }
    
    @MainActor
    func didChangeInput() {
        cancelValidationTask()
        let checkTask = Task.detached { [weak self] () -> UDWalletWithPrivateSeed? in
            guard let self = self else { return nil }
            
            let wallet = await self.getWalletForCurrentInput()
            try Task.checkCancellation()
            return wallet
        }
        self.validationTask = checkTask
        
        checkPasteButtonHidden()
        view?.setContinueButtonEnabled(false)
        view?.setInputState(.default)
            
        Task {
            do {
                if let wallet = try await checkTask.value {
                    let isEnabled = shouldImport(wallet: wallet)
                    await MainActor.run {
                        view?.setContinueButtonEnabled(isEnabled)
                    }
                }
            }
        }
    }
    
    func didTapContinueButton() {
        Task {
            guard let view = self.view else { return }
            
            let input = await MainActor.run { () -> String in
                let input = view.input.trimmedSpaces
                view.setContinueButtonEnabled(false)
                return input
            }
            
            switch walletType {
            case .verified:
                do {
                    let wallet: UDWallet
                    
                    if input.isValidPrivateKey() {
                        wallet = try await udWalletsService.importWalletWith(privateKey: input)
                    } else {
                        wallet = try await udWalletsService.importWalletWith(mnemonics: input)
                    }
                    await MainActor.run {
                        view.setContinueButtonEnabled(true)
                        didCreateWallet(wallet: wallet)
                    }
                } catch WalletError.ethWalletAlreadyExists {
                    await MainActor.run {
                        view.setContinueButtonEnabled(true)
                        view.showSimpleAlert(title: String.Constants.connectionFailed.localized(),
                                             body: String.Constants.walletAlreadyConnectedError.localized())
                    }
                } catch {
                    await MainActor.run {
                        view.setContinueButtonEnabled(true)
                    }
                    Debugger.printFailure("Failed to create a wallet, error: \(error)", critical: true)
                }
            case .readOnly:
                Debugger.printFailure("Does not supported", critical: true)
            }
        }
    }
    
    func didTapPasteButton() {
        let text = UIPasteboard.general.string ?? ""
        view?.setInput(text)
    }
}

// MARK: - Private methods
private extension BaseAddWalletPresenter {
    func cancelValidationTask() {
        validationTask?.cancel()
        validationTask = nil
    }
    
    func getWalletForCurrentInput() async -> UDWalletWithPrivateSeed? {
        guard let view = self.view else { return nil }
        let input = await view.input

        if input.isValidPrivateKey() {
            return await udWalletsService.createWalletFor(privateKey: input)
        } else if input.isValidSeedPhrase() {
            return await udWalletsService.createWalletFor(mnemonics: input)
        }
        return nil
    }
    
    func isInputValid() async -> Bool {
        guard let view = self.view else { return false }
        
        let input = await view.input
        
        switch walletType {
        case .verified:
            if input.isValidPrivateKey() {
                return await udWalletsService.isValid(privateKey: input)
            } else if input.isValidSeedPhrase() {
                return await udWalletsService.isValid(mnemonics: input)
            }
            return false
        case .readOnly:
            return input.isValidDomainName() || input.isValidAddress()
        }
    }
    
    @MainActor
    func createWatchWalletWith(walletAddress: HexAddress) {
        defer { view?.setContinueButtonEnabled(true) }
        
        guard let udWallet = UDWallet.createUnverified(address: walletAddress) else {
            Debugger.printFailure("Failed to create an unverified wallet")
            view?.showSimpleAlert(title: String.Constants.creationFailed.localized(),
                                  body: String.Constants.failedToCreateWatchWallet.localized())
            return
        }
        
        guard !udWallet.isAlreadyConnected() else {
            view?.showSimpleAlert(title: String.Constants.connectionFailed.localized(),
                                  body: String.Constants.walletAlreadyConnectedError.localized())
            return
        }
        
        didCreateWallet(wallet: udWallet)
    }
    
    @MainActor
    func checkPasteButtonHidden() {
        guard let view = self.view else { return }
        
        let input = view.input
        view.setPasteButtonHidden(!input.isEmpty)
    }
}

// MARK: - WalletType
extension BaseAddWalletPresenter {
    enum RestorationWalletType: Codable {
        case verified
        case readOnly
        
        var hintPhrase: String {
            switch self {
            case .verified:
                return String.Constants.addWalletManageHint.localized()
            case .readOnly:
                return String.Constants.addWalletWatchHint.localized()
            }
        }
    }
    
    enum ImportVerifiedWalletType {
        case privateKey(_ privateKey: String)
        case mnemonics(_ mnemonics: String)
    }
}
