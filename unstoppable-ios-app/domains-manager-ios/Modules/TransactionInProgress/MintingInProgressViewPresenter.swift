//
//  MintingInProgressViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import Foundation

final class MintingInProgressViewPresenter: BaseMintingTransactionInProgressViewPresenter {
    
    private weak var mintDomainsFlowManager: MintDomainsFlowManager?
    override var analyticsName: Analytics.ViewName { .primaryDomainMintingInProgress }

    init(view: TransactionInProgressViewProtocol,
         mintingDomains: [MintingDomain],
         transactionsService: DomainTransactionsServiceProtocol,
         mintDomainsFlowManager: MintDomainsFlowManager,
         notificationsService: NotificationsServiceProtocol) {
        super.init(view: view,
                   mintingDomains: mintingDomains,
                   transactionsService: transactionsService,
                   notificationsService: notificationsService)
        self.mintDomainsFlowManager = mintDomainsFlowManager
    }
    
    override func fillUpMintingDomains(in snapshot: inout TransactionInProgressSnapshot) {
        if pendingDomains.count == 1 {
            snapshot.appendSections([.card])
            snapshot.appendItems([.card(domain: pendingDomains[0].name)])
        } else {
            snapshot.appendSections([.list])
            snapshot.appendItems(pendingDomains.map({
                TransactionInProgressViewController.Item.list(domain: $0.name, isPrimary: $0.name == primaryDomain?.name)
            }))
        }
    }
    
    override func didRefreshPendingDomains() {
        if pendingDomains.isEmpty {
            stopTimer()
            Task {
                try? await mintDomainsFlowManager?.handle(action: .mintingCompleted(isPrimary: primaryDomain != nil))
            }
        }
    }
}
