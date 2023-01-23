//
//  ReverseResolutionTransactionInProgressViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.09.2022.
//

import Foundation

class ReverseResolutionTransactionInProgressViewPresenter: BaseTransactionInProgressViewPresenter {
    
    override var analyticsName: Analytics.ViewName { .primaryDomainMintingInProgress }
    private let domain: DomainItem
    private let walletInfo: WalletDisplayInfo
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private var domainTransaction: TransactionItem?
    override var isNavBarHidden: Bool { false }
    override var content: TransactionInProgressViewController.HeaderDescription.Content { .reverseResolution }
    
    init(view: TransactionInProgressViewProtocol,
         domain: DomainItem,
         walletInfo: WalletDisplayInfo,
         transactionsService: DomainTransactionsServiceProtocol,
         notificationsService: NotificationsServiceProtocol,
         dataAggregatorService: DataAggregatorServiceProtocol) {
        self.domain = domain
        self.walletInfo = walletInfo
        self.dataAggregatorService = dataAggregatorService
        super.init(view: view,
                   transactionsService: transactionsService,
                   notificationsService: notificationsService)
    }
    
    override func fillUpMintingDomains(in snapshot: inout TransactionInProgressSnapshot) {
        snapshot.appendSections([.card])
        snapshot.appendItems([.reverseResolutionCard(domain: domain, walletInfo: walletInfo)])
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

            await view?.setViewTransactionButtonHidden(domainTransaction?.transactionHash == nil)
            if domainTransaction == nil {
                await dataAggregatorService.aggregateData()
                await dismiss()
            } else {
                await showData()
            }
        }
    }
}
