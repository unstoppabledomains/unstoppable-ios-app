//
//  DomainsListPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.06.2022.
//

import UIKit

final class DomainsListPresenter: DomainsListViewPresenter {
    
    private let walletWithInfo: WalletWithInfo
    override var analyticsName: Analytics.ViewName { .domainsList }
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var title: String { String.Constants.domains.localized().capitalizedFirstCharacter + " · \(domains.count)" }

    init(view: DomainsListViewProtocol,
         domains: [DomainDisplayInfo],
         walletWithInfo: WalletWithInfo) {
        self.walletWithInfo = walletWithInfo
        super.init(view: view, domains: domains)
        appContext.dataAggregatorService.addListener(self)
    }
    
    @MainActor
    override func viewDidLoad() {
        super.viewDidLoad()
        showDomains()
    }
    
    @MainActor
    override func didSelectItem(_ item: DomainsListViewController.Item) {
        switch item {
        case .searchEmptyState:
            Debugger.printFailure("Unexpected event", critical: true)
            return
        case .domainListItem(let domain, _):
            logAnalytic(event: .domainPressed, parameters: [.domainName : domain.name])
            showProfile(of: domain)
        case .domainsMintingInProgress:
            logAnalytic(event: .mintingDomainsPressed)
            showDomainsMintingInProgress()
        }
    }
}

// MARK: - DataAggregatorServiceListener
extension DomainsListPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        Task {
            await MainActor.run {
                switch result {
                case .success(let resultType):
                    switch resultType {
                    case .domainsUpdated(let domains), .domainsPFPUpdated(let domains):
                        let isDomainsChanged = self.domains != domains
                        if isDomainsChanged {
                            let wallet = walletWithInfo.wallet
                            self.domains = domains.filter({ $0.isOwned(by: [wallet])})
                            showDomains()
                        }
                    case .primaryDomainChanged, .walletsListUpdated: return
                    }
                case .failure:
                    return
                }
            }
        }
    }
}

// MARK: - Private methods
private extension DomainsListPresenter {
    @MainActor
    func showDomains() {
        var snapshot = DomainsListSnapshot()
        
        var otherDomains: [DomainDisplayInfo] = []
        var mintingDomains: [DomainDisplayInfo] = []
        
        for domain in domains {
            if domain.isMinting {
                mintingDomains.append(domain)
            } else {
                otherDomains.append(domain)
            }
        }
        
        if !mintingDomains.isEmpty {
            snapshot.appendSections([.minting])
            snapshot.appendItems([.domainsMintingInProgress(domainsCount: mintingDomains.count)])
        }
        
        if !otherDomains.isEmpty {
            snapshot.appendSections([.other]) // For other domains
            snapshot.appendItems(otherDomains.map({ DomainsListViewController.Item.domainListItem($0,
                                                                                                  isSelectable: true) }))
        }
        
        view?.applySnapshot(snapshot, animated: false)
    }

    @MainActor
    func showProfile(of domain: DomainDisplayInfo) {
        guard let nav = self.view?.cNavigationController,
            let walletInfo = walletWithInfo.displayInfo else { return }
        
        UDVibration.buttonTap.vibrate()
        Task {
            await UDRouter().pushDomainProfileScreen(in: nav, domain: domain, wallet: walletWithInfo.wallet, walletInfo: walletInfo)
        }
    }
    
    @MainActor
    func showDomainsMintingInProgress() {
        guard let view else { return }

        let mintingDomainsDisplayInfo = domains.filter { $0.isMinting }
        let mintingDomains = MintingDomainsStorage.retrieveMintingDomains()
        
        let mintingDomainsWithDisplayInfo = mintingDomainsDisplayInfo.compactMap({ mintingDomainDisplayInfo -> MintingDomainWithDisplayInfo? in
            guard let mintingDomain = mintingDomains.first(where: { $0.name == mintingDomainDisplayInfo.name }) else { return nil }
            
            return MintingDomainWithDisplayInfo(mintingDomain: mintingDomain,
                                                displayInfo: mintingDomainDisplayInfo)
        })
        
        UDRouter().showMintingDomainsInProgressScreen(mintingDomainsWithDisplayInfo: mintingDomainsWithDisplayInfo,
                                                      mintingDomainSelectedCallback: nil,
                                                      in: view)
    }
}
