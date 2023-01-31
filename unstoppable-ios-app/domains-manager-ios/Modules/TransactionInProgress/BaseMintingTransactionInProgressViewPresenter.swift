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
    
    func didRefreshPendingDomains() { }
    
    override func viewTransactionButtonPressed() {
        Task {
            let transactions = pendingDomains.compactMap({ $0.transactionHash })
            if transactions.count > 1 {
                await view?.openLink(.polygonScanAddress(pendingDomains[0].walletAddress))
            } else if transactions.count == 1 {
                await view?.openLink(.polygonScanTransaction(transactions[0]))
            }
        }
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
            try MintingDomainsStorage.save(mintingDomains: pendingDomains)
            
            await MainActor.run {
                let hasTransactionHash = pendingDomains.first(where: { $0.transactionHash != nil }) != nil
                view?.setViewTransactionButtonHidden(!hasTransactionHash)
                showData()
            }
            didRefreshPendingDomains()
        }
    }
}

// MARK: - Open methods
extension BaseMintingTransactionInProgressViewPresenter {
    var primaryDomain: MintingDomain? { mintingDomains.first(where: { $0.isPrimary })}
    var pendingDomains: [MintingDomain] { mintingDomains.filter({ $0.isMinting })}
}

struct MintingDomain: Codable {
    let name: String
    let walletAddress: String
    let isPrimary: Bool
    var isMinting: Bool = true
    let transactionId: UInt64
    var transactionHash: String?
}
