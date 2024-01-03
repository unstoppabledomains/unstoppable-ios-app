//
//  BaseExternalWalletConnectedPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.05.2022.
//

import UIKit

@MainActor
protocol WalletConnectedPresenterProtocol: BasePresenterProtocol {
    var analyticsName: Analytics.ViewName { get }
    
    func didTapContinueButton()
}

@MainActor
class BaseExternalWalletConnectedPresenter: WalletConnectedPresenterProtocol {
    
    var wallet: UDWallet? { nil }
    weak var view: WalletConnectedViewControllerProtocol?
    var analyticsName: Analytics.ViewName { .unspecified }
    
    init(view: WalletConnectedViewControllerProtocol) {
        self.view = view
    }
    
    func viewDidLoad() {
        guard let wallet = self.wallet,
              let record = wallet.getExternalWallet() else {
            Debugger.printFailure("No wallet or WC record to proceed", critical: true)
            return
        }
        
        let walletAddress = wallet.address.walletAddressTruncated
        view?.setWalletAddress(walletAddress)
        if let make = record.make {
            view?.setWalletIcon(make.icon)
        }
    }
    
    // MARK: - WalletConnectedPresenterProtocol
    func didTapContinueButton() { }
}
