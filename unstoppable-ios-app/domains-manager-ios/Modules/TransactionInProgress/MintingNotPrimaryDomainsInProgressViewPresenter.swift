//
//  MintingNotPrimaryDomainsInProgressViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.06.2022.
//

import Foundation

typealias MintingDomainSelectedCallback = (DomainDisplayInfo)->()

final class MintingNotPrimaryDomainsInProgressViewPresenter: BaseMintingTransactionInProgressViewPresenter {
    
    override var analyticsName: Analytics.ViewName { .mintingInProgressDomainsList }
    
    private let mintingDomainsWithDisplayInfo: [MintingDomainWithDisplayInfo]
    private var mintingDomainSelectedCallback: MintingDomainSelectedCallback?
    
    init(view: TransactionInProgressViewProtocol,
         mintingDomainsWithDisplayInfo: [MintingDomainWithDisplayInfo],
         mintingDomainSelectedCallback: MintingDomainSelectedCallback?,
         transactionsService: DomainTransactionsServiceProtocol,
         notificationsService: NotificationsServiceProtocol) {
        self.mintingDomainsWithDisplayInfo = mintingDomainsWithDisplayInfo
        self.mintingDomainSelectedCallback = mintingDomainSelectedCallback
        let mintingDomains = mintingDomainsWithDisplayInfo.map({ $0.mintingDomain })
        super.init(view: view,
                   mintingDomains: mintingDomains,
                   transactionsService: transactionsService,
                   notificationsService: notificationsService)
    }
    
    override func fillUpMintingDomains(in snapshot: inout TransactionInProgressSnapshot) {
        let pendingDomainsNames = Set(pendingDomains.map({ $0.name }))
        let pendingDomainsWithInfo = mintingDomainsWithDisplayInfo.filter({ pendingDomainsNames.contains($0.displayInfo.name) })
        
        if pendingDomainsWithInfo.count == 1 {
            snapshot.appendSections([.card])
            snapshot.appendItems([.card(domain: pendingDomainsWithInfo[0].displayInfo.name)])
        } else {
            snapshot.appendSections([.list])
            snapshot.appendItems(pendingDomainsWithInfo.map({
                TransactionInProgressViewController.Item.mintingList(domain: $0.displayInfo,
                                                                     isSelectable: isSelectable)
            }))
        }
    }
    
    override func didRefreshPendingDomains() {
        
        if pendingDomains.isEmpty {
            Task {
                if Constants.isTestingMinting {
                    return // Don't close screen due to BE issues that prevent from regular testing
                }
                await dismiss()
            }
        }
    }
    
    override func didSelectItem(_ item: TransactionInProgressViewController.Item) {
        Task { @MainActor in
            UDVibration.buttonTap.vibrate()
            switch item {
            case .mintingList(let domain, _):
                if isSelectable {
                    logAnalytic(event: .mintingDomainPressed, parameters: [.domainName: domain.name])
                    dismiss()
                    mintingDomainSelectedCallback?(domain)
                }
            default:
                return
            }
        }
    }
}

// MARK: - Private methods
private extension MintingNotPrimaryDomainsInProgressViewPresenter {
    var isSelectable: Bool { mintingDomainSelectedCallback != nil }
}
