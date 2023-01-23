//
//  ConnectExternalWalletPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.05.2022.
//

import UIKit

final class ConnectNewExternalWalletPresenter: ConnectExternalWalletViewPresenter {
    
    private weak var addWalletFlowManager: AddWalletFlowManager?

    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .connectNewExternalWalletSelection }

    init(view: ConnectExternalWalletViewProtocol,
         addWalletFlowManager: AddWalletFlowManager,
         udWalletsService: UDWalletsServiceProtocol,
         walletConnectClientService: WalletConnectClientServiceProtocol) {
        self.addWalletFlowManager = addWalletFlowManager
        super.init(view: view,
                   udWalletsService: udWalletsService,
                   walletConnectClientService: walletConnectClientService)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.setDashesProgress(nil)
    }
    
    override func didConnectWallet(wallet: UDWallet) {
        super.didConnectWallet(wallet: wallet)
        
        addWalletFlowManager?.wallet = wallet
        DispatchQueue.main.async { [weak self] in
            self?.addWalletFlowManager?.moveToStep(.externalWalletConnected)
        }
    }
}
