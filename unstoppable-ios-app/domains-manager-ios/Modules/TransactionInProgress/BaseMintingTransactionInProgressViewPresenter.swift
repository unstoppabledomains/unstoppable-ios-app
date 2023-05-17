//
//  BaseMintingTransactionInProgressViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.09.2022.
//

import Foundation

class BaseMintingTransactionInProgressViewPresenter: BaseTransactionInProgressViewPresenter {
    
    private(set) var mintingDomains: [MintingDomain]
    override var content: TransactionInProgressViewController.HeaderDescription.Content { .minting }

    init(view: TransactionInProgressViewProtocol,
         mintingDomains: [MintingDomain],
         transactionsService: DomainTransactionsServiceProtocol,
         notificationsService: NotificationsServiceProtocol) {
        self.mintingDomains = mintingDomains.sorted(by: { $0.isPrimary && !$1.isPrimary })
        super.init(view: view,
                   transactionsService: transactionsService,
                   notificationsService: notificationsService)
        appContext.externalEventsService.addListener(self)
    }

    func didRefreshPendingDomains() { }
    
    override func viewTransactionButtonPressed() {
        view?.cNavigationController?.popViewController(animated: true)
    }
     
    override func refreshMintingTransactions() {
        Task {
            let transactions = try await transactionsService.updateTransactionsListFor(domains: mintingDomains.map({ $0.name }))
            
            for i in 0..<mintingDomains.count {
                if let domainMintingTransaction = transactions.first(where: {
                    guard let txDomainName = $0.domainName else { return false }
                    return $0.isMintingTransaction() && txDomainName == mintingDomains[i].name }) {
                    mintingDomains[i].isMinting = domainMintingTransaction.isPending
                    mintingDomains[i].transactionHash = domainMintingTransaction.transactionHash
                }
            }
            
            let pendingDomains = self.pendingDomains
            
            await MainActor.run {
                view?.setActionButtonHidden(pendingDomains.count != 1)
                showData()
            }
            didRefreshPendingDomains()
        }
    }
    
    override func setActionButtonStyle() {
        view?.setActionButtonStyle(.goHome)
    }
}

// MARK: - ExternalEventsServiceListener
extension BaseMintingTransactionInProgressViewPresenter: ExternalEventsServiceListener {
    func didReceive(event: ExternalEvent) {
        Task {
            switch event {
            case .mintingFinished, .domainTransferred:
                refreshMintingTransactions()
            case .wcDeepLink, .walletConnectRequest, .recordsUpdated, .reverseResolutionSet, .reverseResolutionRemoved, .domainProfileUpdated, .parkingStatusLocal, .badgeAdded:
                return
            }
        }
    }
}

// MARK: - Open methods
extension BaseMintingTransactionInProgressViewPresenter {
    var pendingDomains: [MintingDomain] { mintingDomains.filter({ $0.isMinting })}
}


