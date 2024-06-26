//
//  TransferDomainTransactionInProgressViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2023.
//

import Foundation

class TransferDomainTransactionInProgressViewPresenter: BaseTransactionInProgressViewPresenter {
    
    private let domainDisplayInfo: DomainDisplayInfo
    private var domainTransaction: TransactionItem?
    override var analyticsName: Analytics.ViewName { .primaryDomainMintingInProgress }
    override var content: TransactionInProgressViewController.HeaderDescription.Content { .transfer }
    
    
    init(view: TransactionInProgressViewProtocol,
         domainDisplayInfo: DomainDisplayInfo,
         transactionsService: DomainTransactionsServiceProtocol,
         notificationsService: NotificationsServiceProtocol) {
        self.domainDisplayInfo = domainDisplayInfo
        super.init(view: view,
                   transactionsService: transactionsService,
                   notificationsService: notificationsService)
        appContext.externalEventsService.addListener(self)
    }
    
    override func fillUpMintingDomains(in snapshot: inout TransactionInProgressSnapshot) {
        snapshot.appendSections([.card])
        snapshot.appendItems([.domainCard(domain: domainDisplayInfo)])
    }
    
    override func viewTransactionButtonPressed() {
        guard let transactionHash = self.domainTransaction?.transactionHash else { return }
        
        view?.openLink(.polygonScanTransaction(transactionHash))
    }
    
    override func refreshMintingTransactions() {
        Task {
            let transactions = try await transactionsService.updatePendingTransactionsListFor(domains: [domainDisplayInfo.name])
            
            if let domainReverseResolutionTransaction = transactions
                .filterPending(extraCondition: { $0.operation == .transferDomain })
                .first {
                domainTransaction = domainReverseResolutionTransaction
            } else {
                domainTransaction = nil
            }
            
            view?.setActionButtonHidden(domainTransaction?.transactionHash == nil)
            if domainTransaction == nil {
                dismiss()
                if !isNotificationPermissionsGranted {
                    await refreshDataForWalletWith(address: domainDisplayInfo.ownerWallet)
                }
            } else {
                showData()
            }
        }
    }
}

// MARK: - ExternalEventsServiceListener
extension TransferDomainTransactionInProgressViewPresenter: ExternalEventsServiceListener {
    func didReceive(event: ExternalEvent) {
        Task {
            switch event {
            case .recordsUpdated, .reverseResolutionSet, .reverseResolutionRemoved, .domainTransferred:
                refreshMintingTransactions()
            case .wcDeepLink, .walletConnectRequest, .mintingFinished, .domainProfileUpdated, .parkingStatusLocal, .badgeAdded, .chatMessage, .chatChannelMessage, .chatXMTPMessage, .chatXMTPInvite, .domainFollowerAdded:
                return
            }
        }
    }
}
