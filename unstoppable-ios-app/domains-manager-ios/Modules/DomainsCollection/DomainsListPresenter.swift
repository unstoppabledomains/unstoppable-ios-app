//
//  DomainsListPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.06.2022.
//

import UIKit

final class DomainsListPresenter: ViewAnalyticsLogger {
    
    private weak var view: DomainsCollectionViewProtocol?
    private var domains: [DomainItem]
    private let walletWithInfo: WalletWithInfo
    private let reverseResolutionDomain: DomainItem?
    var analyticsName: Analytics.ViewName { .domainsList }
    var scrollableContentYOffset: CGFloat { 48 }
    var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }

    init(view: DomainsCollectionViewProtocol,
         domains: [DomainItem],
         walletWithInfo: WalletWithInfo,
         reverseResolutionDomain: DomainItem?) {
        self.view = view
        self.domains = domains
        self.walletWithInfo = walletWithInfo
        self.reverseResolutionDomain = reverseResolutionDomain
        appContext.dataAggregatorService.addListener(self)
    }
    
}

// MARK: - DomainsCollectionPresenterProtocol
extension DomainsListPresenter: DomainsCollectionPresenterProtocol {
    func viewDidLoad() {
        Task(priority: .high) {
            await MainActor.run {
                view?.setVisualisationControlSelectedSegmentIndex(1)
                view?.setEmptyState(hidden: true)
                view?.setSettingsButtonHidden(true)
                view?.setScrollEnabled(true)
                view?.setTitle(String.Constants.domains.localized().capitalizedFirstCharacter + " · \(domains.count)")
                setupLayout()
                showDomains()
            }
        }
    }
    @MainActor
    func didSelectItem(_ item: DomainsCollectionViewController.Item) {
        switch item {
        case .domainCardItem, .emptyList, .empty, .searchEmptyState, .emptyTopInfo:
            Debugger.printFailure("Unexpected event", critical: true)
            return
        case .domainListItem(let domain, _, _, _):
            logAnalytic(event: .domainPressed, parameters: [.domainName : domain.name])
            showProfile(of: domain)
        case .domainsMintingInProgress:
            logAnalytic(event: .mintingDomainsPressed)
        }
    }
    func didChangeDomainsVisualisation(_ domainsVisualisation: DomainsCollectionViewController.DomainsVisualisation) { }
    func didTapSettingsButton() { }
    func didTapAddButton() { }
    func didPressScanButton() { }
    func didSearchDomainsWith(key: String) { }
    func didMintDomains(result: MintDomainsNavigationController.MintDomainsResult) { }
    func didStartSearch() { }
    func didStopSearch() { }
    func didRecognizeQRCode() {}
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
        var snapshot = DomainsCollectionSnapshot()
                
        var primaryDomain: DomainItem?
        var otherDomains: [DomainItem] = []
        var mintingDomains: [DomainItem] = []
        
        for domain in domains {
            if domain.isPrimary == true {
                primaryDomain = domain
            } else if domain.isMinting {
                mintingDomains.append(domain)
            } else {
                otherDomains.append(domain)
            }
        }
        
        if let primaryDomain = primaryDomain {
            snapshot.appendSections([.primary]) // For primary domain
            snapshot.appendItems([.domainListItem(primaryDomain,
                                                  isUpdatingRecords: primaryDomain.isUpdatingRecords,
                                                  isSelectable: true,
                                                  isReverseResolution: reverseResolutionDomain == primaryDomain)])
        }
        
        if !mintingDomains.isEmpty {
            snapshot.appendSections([.minting])
            snapshot.appendItems([.domainsMintingInProgress(domainsCount: mintingDomains.count)])
        }
        
        if !otherDomains.isEmpty {
            snapshot.appendSections([.other]) // For other domains
            snapshot.appendItems(otherDomains.map({ DomainsCollectionViewController.Item.domainListItem($0,
                                                                                                        isUpdatingRecords: $0.isUpdatingRecords,
                                                                                                        isSelectable: true,
                                                                                                        isReverseResolution: $0 == reverseResolutionDomain) }))
        }
        
        view?.applySnapshot(snapshot, animated: false)
    }
    
    @MainActor
    func setupLayout() {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let section = NSCollectionLayoutSection.flexibleListItemSection(height: 72)
            let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
            section.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                            leading: spacing + 1,
                                                            bottom: 1,
                                                            trailing: spacing + 1)
            
            if sectionIndex == 0 {
                let topInset: CGFloat = 76
                background.contentInsets.top = topInset
                section.contentInsets.top = topInset
            }
            
            section.decorationItems = [
                background
            ]
            
            return section
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        view?.setLayout(layout)
    }
    
    @MainActor
    func showProfile(of domain: DomainItem) {
        guard let nav = self.view?.cNavigationController,
            let walletInfo = walletWithInfo.displayInfo else { return }
        
        UDVibration.buttonTap.vibrate()
        Task {
            await UDRouter().pushDomainProfileScreen(in: nav, domain: domain, wallet: walletWithInfo.wallet, walletInfo: walletInfo)
        }
    }
}
