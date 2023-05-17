//
//  ReverseResolutionTransactionInProgressViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.09.2022.
//

import Foundation

class ReverseResolutionTransactionInProgressViewPresenter: BaseTransactionInProgressViewPresenter {
    
    override var analyticsName: Analytics.ViewName { .reverseResolutionTransactionInProgress }
    private let domain: DomainItem
    private let domainDisplayInfo: DomainDisplayInfo
    private let walletInfo: WalletDisplayInfo
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private var domainTransaction: TransactionItem?
    override var content: TransactionInProgressViewController.HeaderDescription.Content { .reverseResolution }
    
    init(view: TransactionInProgressViewProtocol,
         domain: DomainItem,
         domainDisplayInfo: DomainDisplayInfo,
         walletInfo: WalletDisplayInfo,
         transactionsService: DomainTransactionsServiceProtocol,
         notificationsService: NotificationsServiceProtocol,
         dataAggregatorService: DataAggregatorServiceProtocol) {
        self.domain = domain
        self.domainDisplayInfo = domainDisplayInfo
        self.walletInfo = walletInfo
        self.dataAggregatorService = dataAggregatorService
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
        Task {
            guard let transactionHash = self.domainTransaction?.transactionHash else { return }
            
            await view?.openLink(.polygonScanTransaction(transactionHash))
        }
    }
    
    override func refreshMintingTransactions() {
        Task {
            let transactions = try await transactionsService.updateTransactionsListFor(domains: [domain.name])

            if let domainReverseResolutionTransaction = transactions
                                                            .filterPending(extraCondition: {$0.operation == .setReverseResolution})
                                                            .first {
                domainTransaction = domainReverseResolutionTransaction
            } else {
                domainTransaction = nil
            }

            await view?.setActionButtonHidden(domainTransaction?.transactionHash == nil)
            if domainTransaction == nil {
                await dismiss()
                if !isNotificationPermissionsGranted {
                    await dataAggregatorService.aggregateData(shouldRefreshPFP: false)
                }
            } else {
                await showData()
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
            case .wcDeepLink, .walletConnectRequest, .domainTransferred, .mintingFinished, .domainProfileUpdated, .parkingStatusLocal, .badgeAdded:
                return
            }
        }
    }
}
