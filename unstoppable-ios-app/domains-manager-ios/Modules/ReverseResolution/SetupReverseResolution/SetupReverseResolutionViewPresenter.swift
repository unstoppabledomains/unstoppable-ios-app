//
//  SetupReverseResolutionViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.09.2022.
//

import Foundation

protocol SetupReverseResolutionViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    var navBackStyle: BaseViewController.NavBackIconStyle { get }

    func confirmButtonPressed()
    func skipButtonPressed()
}

class SetupReverseResolutionViewPresenter {
    private(set) weak var view: SetupReverseResolutionViewProtocol?
    private let udWalletsService: UDWalletsServiceProtocol
    let wallet: UDWallet
    let walletInfo: WalletDisplayInfo
    let domain: DomainItem?
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var analyticsName: Analytics.ViewName { .unspecified }

    init(view: SetupReverseResolutionViewProtocol,
         wallet: UDWallet,
         walletInfo: WalletDisplayInfo,
         domain: DomainItem?,
         udWalletsService: UDWalletsServiceProtocol) {
        self.view = view
        self.wallet = wallet
        self.walletInfo = walletInfo
        self.domain = domain
        self.udWalletsService = udWalletsService
    }
    
    func viewDidLoad() {
        Task {
            await view?.setWith(walletInfo: walletInfo, domain: domain)
        }
    }
    func confirmButtonPressed() {
        logButtonPressedAnalyticEvents(button: .confirm)
    }
    func skipButtonPressed() {
        logButtonPressedAnalyticEvents(button: .skip)
    }
    func setupReverseResolutionFor(domain: DomainItem) async throws {
        guard let view = self.view else { return }
        
        try await udWalletsService.setReverseResolution(to: domain,
                                                        paymentConfirmationDelegate: view)
    }
}

// MARK: - SetupReverseResolutionViewPresenterProtocol
extension SetupReverseResolutionViewPresenter: SetupReverseResolutionViewPresenterProtocol {
}

