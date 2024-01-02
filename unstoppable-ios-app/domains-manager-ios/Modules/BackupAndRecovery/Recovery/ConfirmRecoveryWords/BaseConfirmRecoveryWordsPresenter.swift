//
//  BaseConfirmRecoveryWordsPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

@MainActor
protocol ConfirmWordsPresenterProtocol: BasePresenterProtocol {
    var indices: [Int] { get }
    var progress: Double? { get }
    var analyticsName: Analytics.ViewName { get }
    
    func didConfirmWords()
}

@MainActor
class BaseConfirmRecoveryWordsPresenter {
    private var mnems: [String] = []
    weak var view: ConfirmWordsViewControllerProtocol?
    var wallet: UDWallet? { nil }
    var progress: Double? { nil }
    var analyticsName: Analytics.ViewName { .unspecified }
    
    let indices = [0, 3, 7, 11]
    
    init(view: ConfirmWordsViewControllerProtocol) {
        self.view = view
    }
    
    func viewDidLoad() {
        configureMnems()
    }
    func didConfirmWords() { }
}

// MARK: - ConfirmWordsPresenterProtocol
extension BaseConfirmRecoveryWordsPresenter: ConfirmWordsPresenterProtocol { }

// MARK: - Private methods
private extension BaseConfirmRecoveryWordsPresenter {
    func configureMnems() {
        guard let wallet = self.wallet,
              let mnem = wallet.getMnemonics()?.mnemonicsArray else { return }
        configure(with: mnem)
    }
    
    
    func configure(with mnemonics: [String]) {
        let mnemonicsOriginal = mnemonics
        let mnemonicsSorted = mnemonics.sorted(by: < )
        
        var mnemonicsConfirmation = [String]()
        
        for index in indices {
            let confirmationWord = mnemonics[index]
            mnemonicsConfirmation.append(confirmationWord)
        }
        
        view?.setMnems(original: mnemonicsOriginal, sorted: mnemonicsSorted, confirmation: mnemonicsConfirmation)
    }
}

