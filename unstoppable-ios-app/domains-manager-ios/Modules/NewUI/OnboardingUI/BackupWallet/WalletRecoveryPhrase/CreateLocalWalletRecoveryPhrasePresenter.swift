//
//  CreateLocalWalletRecoveryPhrasePresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

final class CreateLocalWalletRecoveryPhrasePresenter: BaseRecoveryPhrasePresenter {
    
    private let addWalletFlowManager: AddWalletFlowManager
    private let mode: Mode
    
    override var wallet: UDWallet? { addWalletFlowManager.wallet }
    
    init(view: RecoveryPhraseViewControllerProtocol,
         mode: Mode,
         addWalletFlowManager: AddWalletFlowManager) {
        self.mode = mode
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        if case .iCloud(let _password) = self.mode {
            view?.hideBackButton()
            if let password = _password {
                saveWalletToiCloud(password: password)
            }
        }
        setupForCurrentMode()
        super.viewDidLoad()
    }
    
    override func doneButtonPressed() {
        switch mode {
        case .iCloud:
            onboardingFinished()
        case .manual:
            showConfirmWordsVC()
        }
    }
    
}

// MARK: - Private methods
private extension CreateLocalWalletRecoveryPhrasePresenter {
    func setupForCurrentMode() {
        view?.setDashesProgress(nil)
        view?.setDistanceToDashesView(-28)
        switch mode {
        case .iCloud:
            view?.setDoneButtonTitle(String.Constants.doneButtonTitle.localized())
        case .manual:
            view?.setSubtitleHidden(true)
            view?.setDoneButtonTitle(String.Constants.iVeSavedThisWords.localized())
        }
    }
    
    func showConfirmWordsVC() {
        addWalletFlowManager.moveToStep(.confirmWords)
    }
    
    func onboardingFinished() {
        addWalletFlowManager.didFinishCreateWalletFlow()
    }
}

// MARK: - Mode
extension CreateLocalWalletRecoveryPhrasePresenter {
    enum Mode {
        case iCloud(password: String?), manual
    }
}
