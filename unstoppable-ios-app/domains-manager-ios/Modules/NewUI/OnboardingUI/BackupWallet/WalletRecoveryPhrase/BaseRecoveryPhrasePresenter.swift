//
//  BaseRecoveryPhrasePresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit
import PromiseKit

protocol RecoveryPhrasePresenterProtocol: BasePresenterProtocol {
    func doneButtonPressed()
    func copyToClipboardButtonPressed()
    func learMoreButtonPressed()
}

class BaseRecoveryPhrasePresenter {
    private(set) var isShowingHelp = false
    private var mnems: [String] = []
    weak var view: RecoveryPhraseViewControllerProtocol?
    var wallet: UDWallet? { nil }
    
    init(view: RecoveryPhraseViewControllerProtocol) {
        self.view = view
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
        showCopiedToClipboard()
        let mnemsString = mnems.joined(separator: " ")
        UIPasteboard.general.string = mnemsString
        Vibration.success.vibrate()
    }
    
    func learMoreButtonPressed() {
        view?.showPullUpMenuWith(preset: .whatIsRecoveryPhrase)
    }
}

// MARK: - Private methods
private extension BaseRecoveryPhrasePresenter {
    func configureMnem() {
        let mnemsMock: [String] = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"]
        configure(with: mnemsMock)
        
        guard let wallet = self.wallet,
              let mnem = wallet.getMnemonics()?.mnemonicsArray else { return }
        configure(with: mnem)
    }
   
    func configure(with mnem: [String]) {
        self.mnems = mnem
        
        view?.clearMnemStacks()
        
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
