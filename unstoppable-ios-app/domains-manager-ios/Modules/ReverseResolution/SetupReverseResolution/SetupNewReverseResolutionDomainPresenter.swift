//
//  SetupNewReverseResolutionDomainPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.09.2022.
//

import Foundation

final class SetupNewReverseResolutionDomainPresenter: SetupReverseResolutionViewPresenter {
    
    var resultCallback: DomainItemSelectedCallback?
    private let domains: [DomainDisplayInfo]
    private let reverseResolutionDomain: DomainDisplayInfo
    override var analyticsName: Analytics.ViewName { .setupReverseResolution }
    
    init(view: SetupReverseResolutionViewProtocol,
         wallet: UDWallet,
         walletInfo: WalletDisplayInfo,
         domains: [DomainDisplayInfo],
         reverseResolutionDomain: DomainDisplayInfo,
         udWalletsService: UDWalletsServiceProtocol,
         resultCallback: @escaping DomainItemSelectedCallback) {
        self.reverseResolutionDomain = reverseResolutionDomain
        self.domains = domains
        super.init(view: view,
                   wallet: wallet,
                   walletInfo: walletInfo,
                   domain: reverseResolutionDomain,
                   udWalletsService: udWalletsService)
        self.resultCallback = resultCallback
    }
    
    override func confirmButtonPressed() {
        super.confirmButtonPressed()
        
        Task {
            guard let view = self.view else { return }

            do {
                try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                try await setupReverseResolutionFor(domain: reverseResolutionDomain)
                finish(result: .domainsOrderAndReverseResolutionSet(domains, reverseResolutionDomain: reverseResolutionDomain))
            } catch {
                await MainActor.run {
                    view.showAlertWith(error: error)
                }
            }
        }
    }
    
    override func skipButtonPressed() {
        super.skipButtonPressed()
        
        finish(result: .domainsOrderSet(domains))
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
