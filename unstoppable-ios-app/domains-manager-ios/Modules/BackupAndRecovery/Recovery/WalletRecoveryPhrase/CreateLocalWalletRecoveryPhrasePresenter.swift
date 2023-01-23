//
//  CreateLocalWalletRecoveryPhrasePresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

final class CreateLocalWalletRecoveryPhrasePresenter: BaseRecoveryPhrasePresenter {
    
    private weak var addWalletFlowManager: AddWalletFlowManager?
    private let mode: Mode
    
    override var wallet: UDWallet? { addWalletFlowManager?.wallet }
    override var analyticsName: Analytics.ViewName { .newWalletRecoveryPhrase }
    
    init(view: RecoveryPhraseViewControllerProtocol,
         recoveryType: UDWallet.RecoveryType,
         mode: Mode,
         addWalletFlowManager: AddWalletFlowManager) {
        self.mode = mode
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view, recoveryType: recoveryType)
    }
    
    override func viewDidLoad() {
        if case .iCloud(_) = self.mode {
            view?.hideBackButton()
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
        switch mode {
        case .iCloud:
            view?.setDoneButtonTitle(String.Constants.doneButtonTitle.localized())
        case .manual:
            view?.setSubtitleHidden(true)
            view?.setDoneButtonTitle(String.Constants.iVeSavedThisWords.localized())
        }
    }
    
    func showConfirmWordsVC() {
        addWalletFlowManager?.moveToStep(.confirmWords)
    }
    
    func onboardingFinished() {
        addWalletFlowManager?.didFinishAddWalletFlow()
    }
}

// MARK: - Mode
extension CreateLocalWalletRecoveryPhrasePresenter {
    enum Mode {
        case iCloud(password: String?), manual
    }
}
