//
//  SetupChangeReverseResolutionDomainPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.09.2022.
//

import Foundation

final class SetupChangeReverseResolutionDomainPresenter: SetupReverseResolutionViewPresenter {
    
    var changedCallback: MainActorAsyncCallback?
    private let selectedDomain: DomainDisplayInfo
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .setupChangeReverseResolution }
    override var domainName: String? { selectedDomain.name }
    
    init(view: SetupReverseResolutionViewProtocol,
         wallet: WalletEntity,
         domain: DomainDisplayInfo,
         udWalletsService: UDWalletsServiceProtocol,
         resultCallback: @escaping MainActorAsyncCallback) {
        self.selectedDomain = domain
        super.init(view: view,
                   wallet: wallet,
                   domain: domain,
                   udWalletsService: udWalletsService)
        self.changedCallback = resultCallback
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            await MainActor.run {
                view?.setSkipButton(hidden: true)
            }
        }
    }
    
    override func confirmButtonPressed() {
        super.confirmButtonPressed()
        
        Task {
            guard let view = self.view else { return }
            
            do {
                try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                try await setupReverseResolutionFor(domain: selectedDomain)
                finish()
            } catch {
                await MainActor.run {
                    view.showAlertWith(error: error)
                }
            }
        }
    }
}

// MARK: - Private functions
private extension SetupChangeReverseResolutionDomainPresenter {
    func finish() {
        Task {
            await view?.cNavigationController?.dismiss(animated: true)
            changedCallback?()
        }
    }
}
