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
    override var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }

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
    
    override func viewTransactionButtonPressed() {
        Task {
            try? await mintDomainsFlowManager?.handle(action: .skipMinting)
        }
    }
    
    override func fillUpMintingDomains(in snapshot: inout TransactionInProgressSnapshot) {
        if pendingDomains.count == 1 {
            snapshot.appendSections([.card])
            snapshot.appendItems([.nameCard(domain: pendingDomains[0].name)])
        } else {
            snapshot.appendSections([.list])
            snapshot.appendItems(pendingDomains.map({
                TransactionInProgressViewController.Item.firstMintingList(domain: $0.name,
                                                              isSelectable: false)
            }))
        }
    }
    
    override func didRefreshPendingDomains() {
        if pendingDomains.isEmpty {
            stopTimer()
            Task {
                try? await mintDomainsFlowManager?.handle(action: .mintingCompleted)
            }
        }
    }
}
