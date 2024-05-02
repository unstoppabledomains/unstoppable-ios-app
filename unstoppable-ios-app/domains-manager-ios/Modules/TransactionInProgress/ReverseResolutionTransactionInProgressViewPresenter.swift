//
//  ReverseResolutionTransactionInProgressViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.09.2022.
//

import Foundation

final class ReverseResolutionTransactionInProgressViewPresenter: BaseTransactionInProgressViewPresenter {
    
    override var analyticsName: Analytics.ViewName { .reverseResolutionTransactionInProgress }
    private let domain: DomainItem
    private let domainDisplayInfo: DomainDisplayInfo
    private let walletInfo: WalletDisplayInfo
    private var domainTransaction: TransactionItem?
    override var content: TransactionInProgressViewController.HeaderDescription.Content { .reverseResolution }
    
    init(view: TransactionInProgressViewProtocol,
         domain: DomainItem,
         domainDisplayInfo: DomainDisplayInfo,
         walletInfo: WalletDisplayInfo,
         transactionsService: DomainTransactionsServiceProtocol,
         notificationsService: NotificationsServiceProtocol) {
        self.domain = domain
        self.domainDisplayInfo = domainDisplayInfo
        self.walletInfo = walletInfo
        super.init(view: view,
                   transactionsService: transactionsService,
                   notificationsService: notificationsService)
        appContext.externalEventsService.addListener(self)
    }
    
    override func fillUpMintingDomains(in snapshot: inout TransactionInProgressSnapshot) {
        snapshot.appendSections([.card])
        snapshot.appendItems([.reverseResolutionCard(domain: domainDisplayInfo, walletInfo: walletInfo)])
    }
        
    override func viewTransactionButtonPressed() {
        guard let transactionHash = self.domainTransaction?.transactionHash else { return }
        
        view?.openLink(.polygonScanTransaction(transactionHash))
    }
    
    override func refreshMintingTransactions() {
        Task {
            let transactions = try await transactionsService.updatePendingTransactionsListFor(domains: [domain])

            if let domainReverseResolutionTransaction = transactions
                                                            .filterPending(extraCondition: { $0.operation == .setReverseResolution})
                                                            .first {
                domainTransaction = domainReverseResolutionTransaction
            } else {
                domainTransaction = nil
            }

            view?.setActionButtonHidden(domainTransaction?.transactionHash == nil)
            if domainTransaction == nil {
                dismiss()
                if !isNotificationPermissionsGranted {
                    await refreshDataForWalletWith(address: walletInfo.address)
                }
            } else {
                showData()
            }
        }
    }
}

// MARK: - ExternalEventsServiceListener
extension ReverseResolutionTransactionInProgressViewPresenter: ExternalEventsServiceListener {
    func didReceive(event: ExternalEvent) {
        Task {
            switch event {
            case .recordsUpdated, .reverseResolutionSet, .reverseResolutionRemoved:
                refreshMintingTransactions()
            case .wcDeepLink, .walletConnectRequest, .domainTransferred, .mintingFinished, .domainProfileUpdated, .parkingStatusLocal, .badgeAdded, .chatMessage, .chatChannelMessage, .chatXMTPMessage, .chatXMTPInvite, .domainFollowerAdded:
                return
            }
        }
    }
}
