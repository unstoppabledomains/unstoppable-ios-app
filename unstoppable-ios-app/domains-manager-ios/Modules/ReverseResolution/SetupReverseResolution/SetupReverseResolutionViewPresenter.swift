//
//  SetupReverseResolutionViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.09.2022.
//

import Foundation

@MainActor
protocol SetupReverseResolutionViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var domainName: String? { get }

    func confirmButtonPressed()
    func skipButtonPressed()
}

@MainActor
class SetupReverseResolutionViewPresenter {
    private(set) weak var view: SetupReverseResolutionViewProtocol?
    private let udWalletsService: UDWalletsServiceProtocol
    let wallet: WalletEntity
    let domain: DomainDisplayInfo?
    var domainName: String? { domain?.name }
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var analyticsName: Analytics.ViewName { .unspecified }

    init(view: SetupReverseResolutionViewProtocol,
         wallet: WalletEntity,
         domain: DomainDisplayInfo?,
         udWalletsService: UDWalletsServiceProtocol) {
        self.view = view
        self.wallet = wallet
        self.domain = domain
        self.udWalletsService = udWalletsService
    }
    
    func viewDidLoad() {
        view?.setWith(walletInfo: wallet.displayInfo, domain: domain)
        view?.setConfirmButton(title: String.Constants.confirm.localized(),
                               icon: nil)
    }
    func confirmButtonPressed() {
        logButtonPressedAnalyticEvents(button: .confirm, parameters: [.domainName: domainName ?? "N/A"])
    }
    func skipButtonPressed() {
        logButtonPressedAnalyticEvents(button: .skip, parameters: [.domainName: domainName ?? "N/A"])
    }
    func setupReverseResolutionFor(domain: DomainDisplayInfo) async throws {
        guard let view = self.view else { return }
        
        let domain = domain.toDomainItem()
        try await udWalletsService.setReverseResolution(to: domain,
                                                        paymentConfirmationDelegate: view)
    }
}

// MARK: - SetupReverseResolutionViewPresenterProtocol
extension SetupReverseResolutionViewPresenter: SetupReverseResolutionViewPresenterProtocol {
}

