//
//  SetupWalletsReverseResolutionPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.09.2022.
//

import Foundation

final class SetupWalletsReverseResolutionPresenter: SetupReverseResolutionViewPresenter {
    
    private weak var setupWalletsReverseResolutionFlowManager: SetupWalletsReverseResolutionFlowManager?
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .walletSetupReverseResolution }

    init(view: SetupReverseResolutionViewProtocol,
         wallet: WalletEntity,
         udWalletsService: UDWalletsServiceProtocol,
         setupWalletsReverseResolutionFlowManager: SetupWalletsReverseResolutionFlowManager) {
        super.init(view: view,
                   wallet: wallet,
                   domain: nil,
                   udWalletsService: udWalletsService)
        self.setupWalletsReverseResolutionFlowManager = setupWalletsReverseResolutionFlowManager
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            await MainActor.run {
                view?.setSkipButton(hidden: true)
                view?.setConfirmButton(title: String.Constants.continue.localized(),
                                       icon: nil)
            }
        }
    }
    
    override func confirmButtonPressed() {
        super.confirmButtonPressed()
        
        Task {
            do {
                try await setupWalletsReverseResolutionFlowManager?.handle(action: .continueReverseResolutionSetup)
            }
        }
    }
    
}
