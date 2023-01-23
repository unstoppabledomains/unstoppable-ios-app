//
//  SetupNewReverseResolutionDomainPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.09.2022.
//

import Foundation

final class SetupNewReverseResolutionDomainPresenter: SetupReverseResolutionViewPresenter {
    
    var resultCallback: DomainItemSelectedCallback?
    private let selectedDomain: DomainItem
    override var analyticsName: Analytics.ViewName { .setupReverseResolution }
    
    init(view: SetupReverseResolutionViewProtocol,
         wallet: UDWallet,
         walletInfo: WalletDisplayInfo,
         domain: DomainItem,
         udWalletsService: UDWalletsServiceProtocol,
         resultCallback: @escaping DomainItemSelectedCallback) {
        self.selectedDomain = domain
        super.init(view: view,
                   wallet: wallet,
                   walletInfo: walletInfo,
                   domain: domain,
                   udWalletsService: udWalletsService)
        self.resultCallback = resultCallback
    }
    
    override func confirmButtonPressed() {
        super.confirmButtonPressed()
        
        Task {
            guard let view = self.view else { return }

            do {
                try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                try await setupReverseResolutionFor(domain: selectedDomain)
                finish(result: .homeAndReverseResolutionSet(selectedDomain))
            } catch {
                await MainActor.run {
                    view.showAlertWith(error: error)
                }
            }
        }
    }
    
    override func skipButtonPressed() {
        super.skipButtonPressed()
        
        finish(result: .homeDomainSet(selectedDomain))
    }
}

// MARK: - Private functions
private extension SetupNewReverseResolutionDomainPresenter {
    func finish(result: SetNewHomeDomainResult) {
        Task {
            await view?.cNavigationController?.dismiss(animated: true)
            resultCallback?(result)
        }
    }
}
