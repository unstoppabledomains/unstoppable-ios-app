//
//  RevealRecoveryPhrasePresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.05.2022.
//

import UIKit

final class RevealRecoveryPhrasePresenter: BaseRecoveryPhrasePresenter {
    
    private let revealWallet: UDWallet
    override var wallet: UDWallet? { revealWallet }
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .revealRecoveryPhrase }
    
    init(view: RecoveryPhraseViewControllerProtocol,
         recoveryType: UDWallet.RecoveryType,
         wallet: UDWallet) {
        self.revealWallet = wallet
        super.init(view: view, recoveryType: recoveryType)
    }
    
    override func viewDidLoad() {
        view?.setDashesProgress(nil)
        view?.setSubtitleHidden(true)
        view?.setDoneButtonHidden(true)
        super.viewDidLoad()
    }
    
}

// MARK: - Private methods
private extension RevealRecoveryPhrasePresenter {
  
}
