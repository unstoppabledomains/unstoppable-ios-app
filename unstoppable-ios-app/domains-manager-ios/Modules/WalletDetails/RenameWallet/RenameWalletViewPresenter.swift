//
//  RenameWalletViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.05.2022.
//

import Foundation

protocol RenameWalletViewPresenterProtocol: BasePresenterProtocol {
    var walletSourceName: String { get }
    var walletAddress: String { get }
    func nameDidChange(_ name: String)
    func doneButtonPressed()
}

@MainActor
final class RenameWalletViewPresenter: WalletDataValidator {
    typealias WalletNameUpdatedCallback = (UDWallet) -> ()
 
    private let udWalletsService: UDWalletsServiceProtocol
    private weak var view: RenameWalletViewProtocol?
    private var wallet: UDWallet
    private var walletDisplayInfo: WalletDisplayInfo
    private var name: String = ""
    var nameUpdatedCallback: WalletNameUpdatedCallback

    init(view: RenameWalletViewProtocol,
         wallet: UDWallet,
         walletDisplayInfo: WalletDisplayInfo,
         udWalletsService: UDWalletsServiceProtocol,
         nameUpdatedCallback: @escaping WalletNameUpdatedCallback) {
        self.view = view
        self.wallet = wallet
        self.walletDisplayInfo = walletDisplayInfo
        self.udWalletsService = udWalletsService
        self.nameUpdatedCallback = nameUpdatedCallback
    }
}

// MARK: - RenameWalletViewPresenterProtocol
extension RenameWalletViewPresenter: RenameWalletViewPresenterProtocol {
    var walletAddress: String { wallet.address }
    
    var walletSourceName: String {
        walletDisplayInfo.walletSourceName
    }
    
    func viewDidLoad() {
        Task {
            await MainActor.run {
                view?.setWalletAddress(walletDisplayInfo.address.walletAddressTruncated)
                view?.setWalletDisplayInfo(walletDisplayInfo)
                
                let name: String
                switch walletDisplayInfo.source {
                case .locallyGenerated:
                    name = walletDisplayInfo.name
                case .external(let walletMakeName, _):
                    name = walletDisplayInfo.isNameSet ? walletDisplayInfo.name : walletMakeName
                    // TODO: - MPC
                case .imported, .mpc:
                    if walletDisplayInfo.isNameSet {
                        name = walletDisplayInfo.name
                    } else {
                        view?.setDoneButtonEnabled(false)
                        name = ""
                    }
                }
                
                self.name = name
                view?.setWalletName(name)
            }
        }
    }
    
    func nameDidChange(_ name: String) {
        validateName(name)
    }
    
    func doneButtonPressed() {
        guard let newWallet = udWalletsService.rename(wallet: wallet, with: name) else { return }
        
        nameUpdatedCallback(newWallet)
        view?.dismiss(animated: true)
    }
}

// MARK: - Private functions
private extension RenameWalletViewPresenter {
    func validateName(_ name: String) {
        Task {
            await MainActor.run {
                let name = name.trimmedSpaces
                let validationResult = self.isNameValid(name, for: walletDisplayInfo)
                
                switch validationResult {
                case .success:
                    self.name = name
                    view?.setDoneButtonEnabled(true)
                    view?.setErrorMessage(nil)
                case .failure(let error):
                    view?.setDoneButtonEnabled(false)
                    view?.setErrorMessage(error.message)
                }
            }
        }
    }
}
