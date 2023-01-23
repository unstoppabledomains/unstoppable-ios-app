//
//  MintingNotPrimaryDomainsInProgressViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.06.2022.
//

import Foundation

final class MintingNotPrimaryDomainsInProgressViewPresenter: BaseMintingTransactionInProgressViewPresenter {
    
    override var analyticsName: Analytics.ViewName { .mintingInProgressDomainsList }
    
    init(view: TransactionInProgressViewProtocol,
         mintingDomains: [DomainItem],
         transactionsService: DomainTransactionsServiceProtocol,
         notificationsService: NotificationsServiceProtocol) {
        let mintingDomains = MintingDomainsStorage.retrieveMintingDomains()
        super.init(view: view,
                   mintingDomains: mintingDomains,
                   transactionsService: transactionsService,
                   notificationsService: notificationsService)
    }
    
    override func fillUpMintingDomains(in snapshot: inout TransactionInProgressSnapshot) {
        snapshot.appendSections([.list])
        snapshot.appendItems(pendingDomains.map({
            TransactionInProgressViewController.Item.list(domain: $0.name, isPrimary: false)
        }))
    }
    
    override func didRefreshPendingDomains() {
        if pendingDomains.isEmpty {
            Task {
                await dismiss()
            }
        }
    }
}
