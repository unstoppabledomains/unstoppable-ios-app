//
//  BaseRecoveryPhrasePresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

protocol RecoveryPhrasePresenterProtocol: BasePresenterProtocol {
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var progress: Double? { get }
    var analyticsName: Analytics.ViewName { get }

    func doneButtonPressed()
    func copyToClipboardButtonPressed()
    func learMoreButtonPressed()
}

class BaseRecoveryPhrasePresenter {
    private(set) var isShowingHelp = false
    private var mnems: [String] = []
    private var privateKey: String = ""
    private var recoveryType: UDWallet.RecoveryType
    weak var view: RecoveryPhraseViewControllerProtocol?
    var wallet: UDWallet? { nil }
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var progress: Double? { nil }
    var analyticsName: Analytics.ViewName { .unspecified }

    init(view: RecoveryPhraseViewControllerProtocol,
         recoveryType: UDWallet.RecoveryType) {
        self.view = view
        self.recoveryType = recoveryType
    }
    
    func viewDidLoad() {
        configureMnem()
    }
    func doneButtonPressed() { }
    
    func saveWalletToiCloud(password: String) {
        guard let wallet = self.wallet else {
            Debugger.printFailure("No wallet to backup", critical: true)
            return
        }
        let success = iCloudWalletStorage.saveToiCloud(wallets: [wallet],
                                                       password: password)
        if !success {
            DispatchQueue.main.async { [weak self] in
                self?.view?.showSimpleAlert(title: String.Constants.saveToICloudFailedTitle.localized(),
                                            body: String.Constants.backupToICloudFailedMessage.localized())
            }
        }
    }
}

// MARK: - RecoveryPhrasePresenterProtocol
extension BaseRecoveryPhrasePresenter: RecoveryPhrasePresenterProtocol {
    func copyToClipboardButtonPressed() {
        let stringToCopy: String
        switch recoveryType {
        case .recoveryPhrase:
            stringToCopy = mnems.joined(separator: " ")
        case .privateKey:
            stringToCopy = privateKey
        }
        UIPasteboard.general.string = stringToCopy
        
        showCopiedToClipboard()
        Vibration.success.vibrate()
    }
    
    func learMoreButtonPressed() {
        UDVibration.buttonTap.vibrate()
        switch recoveryType {
        case .recoveryPhrase:
            view?.showInfoScreenWith(preset: .whatIsRecoveryPhrase)
        case .privateKey:
            // TODO: - Show pull up with preset for private key
            return
        }
    }
}

// MARK: - Private methods
private extension BaseRecoveryPhrasePresenter {
    func configureMnem() {
        guard let wallet = self.wallet else { return }
        
        switch recoveryType {
        case .privateKey:
            guard let privateKey = wallet.getPrivateKey() else { return }

            self.privateKey = privateKey
            view?.setPrivateKey(privateKey)
        case .recoveryPhrase:
            guard let mnem = wallet.getMnemonics()?.mnemonicsArray else { return }
            
            configure(with: mnem)
        }
    }
   
    func configure(with mnem: [String]) {
        self.mnems = mnem
                
        let leftMnems = Array(mnem[0...5])
        let rightMnems = Array(mnem[6...11])
        
        view?.setMnems(leftMnems, rightMnems)
    }
    
    func showCopiedToClipboard() {
        view?.setCopiedToClipboardButtonForState(true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.view?.setCopiedToClipboardButtonForState(false)
        }
    }
}
