//
//  BaseMintingInProgressViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.06.2022.
//

import Foundation
import UIKit

@MainActor
protocol TransactionInProgressViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    var isNavBarHidden: Bool { get }
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    
    func didSelectItem(_ item: TransactionInProgressViewController.Item)
    func viewTransactionButtonPressed()
}

@MainActor
class BaseTransactionInProgressViewPresenter {
    
    private(set) weak var view: TransactionInProgressViewProtocol?
    
    private let notificationsService: NotificationsServiceProtocol
    let transactionsService: DomainTransactionsServiceProtocol
    private var refreshTimer: Timer?
    private(set) var isNotificationPermissionsGranted = false
    var isNavBarHidden: Bool { false }
    nonisolated var analyticsName: Analytics.ViewName { .unspecified }
    var content: TransactionInProgressViewController.HeaderDescription.Content { .minting }
    var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }

    init(view: TransactionInProgressViewProtocol,
         transactionsService: DomainTransactionsServiceProtocol,
         notificationsService: NotificationsServiceProtocol) {
        self.view = view
        self.transactionsService = transactionsService
        self.notificationsService = notificationsService
    }
    
    func fillUpMintingDomains(in snapshot: inout TransactionInProgressSnapshot) { }
    func viewTransactionButtonPressed() { }
    func didSelectItem(_ item: TransactionInProgressViewController.Item) { }
    @MainActor func setActionButtonStyle() {
        view?.setActionButtonStyle(.viewTransaction)
    }
    
    @MainActor
    func dismiss() {
        stopTimer()
        if view?.presentedViewController != nil {
            view?.presentingViewController?.dismiss(animated: true)
        } else {
            view?.dismiss(animated: true)
        }
    }
}

// MARK: - MintingInProgressViewPresenterProtocol
extension BaseTransactionInProgressViewPresenter: TransactionInProgressViewPresenterProtocol {
    func viewDidLoad() {
        Task {
            await checkNotificationPermissions()
            await MainActor.run {
                setActionButtonStyle()
                view?.setActionButtonHidden(true)
                showData()
                startRefreshTransactionsTimer()
            }
            refreshMintingTransactions()
        }
    }
}

// MARK: - Open methods
extension BaseTransactionInProgressViewPresenter {
    func stopTimer() {
        stopRefreshDomainsTimer()
    }
    
    @objc func refreshMintingTransactions() { }
    
    func showData() {
        var snapshot = TransactionInProgressSnapshot()
        
        snapshot.appendSections([.header])
        snapshot.appendItems([.header(.init(action: { [weak self] in self?.askForNotificationPermissions() },
                                            isGranted: isNotificationPermissionsGranted,
                                            content: content))])
        
        fillUpMintingDomains(in: &snapshot)
        
        view?.applySnapshot(snapshot, animated: true)
    }
    
    func refreshDataForWalletWith(address: String?) async {
        guard let wallet = appContext.walletsDataService.wallets.first(where: { $0.address == address }) else { return }
        try? await appContext.walletsDataService.refreshDataForWallet(wallet)
    }
}

// MARK: - Private functions
private extension BaseTransactionInProgressViewPresenter {
    func startRefreshTransactionsTimer() {
        refreshTimer = Timer.scheduledTimer(timeInterval: Constants.updateInterval,
                                            target: self,
                                            selector: #selector(refreshMintingTransactions),
                                            userInfo: nil, repeats: true)
    }
    
    func stopRefreshDomainsTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func askForNotificationPermissions() {
        logButtonPressedAnalyticEvents(button: .notifyWhenFinished)
        Task {
            guard let view = self.view,
                  (await appContext.permissionsService.askPermissionsFor(functionality: .notifications(options: NotificationsService.registerForNotificationsOptions),
                                                                     in: view,
                                                                     shouldShowAlertIfNotGranted: true)) else { return }
            isNotificationPermissionsGranted = true
            notificationsService.registerRemoteNotifications()
            showData()
        }
    }
    
    func checkNotificationPermissions() async {
        self.isNotificationPermissionsGranted = await appContext.permissionsService.checkPermissionsFor(functionality: .notifications(options: []))
        if !isNotificationPermissionsGranted {
            NotificationCenter.default.addObserver(self, selector: #selector(reCheckNotificationPermissions), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }
    
    @objc func reCheckNotificationPermissions() {
        Task {
            await checkNotificationPermissions()
            showData()
        }
    }
}
