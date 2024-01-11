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
            let transactions = try await transactionsService.updatePendingTransactionsListFor(domains: mintingDomains.map({ $0.name }))
            
            for i in 0..<mintingDomains.count {
                let transactionInProgress = transactions.first(where: { $0.domainName == mintingDomains[i].name })
                mintingDomains[i].isMinting = transactionInProgress != nil && transactionInProgress?.isMintingTransaction() == true
                mintingDomains[i].transactionHash = transactionInProgress?.transactionHash
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
    nonisolated
    func didReceive(event: ExternalEvent) {
        Task { @MainActor in 
            switch event {
            case .mintingFinished, .domainTransferred:
                refreshMintingTransactions()
            case .wcDeepLink, .walletConnectRequest, .recordsUpdated, .reverseResolutionSet, .reverseResolutionRemoved, .domainProfileUpdated, .parkingStatusLocal, .badgeAdded, .chatMessage, .chatChannelMessage, .chatXMTPMessage, .chatXMTPInvite, .domainFollowerAdded:
                return
            }
        }
    }
}

// MARK: - Open methods
extension BaseMintingTransactionInProgressViewPresenter {
    var pendingDomains: [MintingDomain] { mintingDomains.filter({ $0.isMinting })}
}


