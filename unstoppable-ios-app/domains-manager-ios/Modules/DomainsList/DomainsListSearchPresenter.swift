//
//  DomainListSearchPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2023.
//

import Foundation

typealias DomainsListSearchCallback = (DomainDisplayInfo) -> ()

final class DomainsListSearchPresenter: DomainsListViewPresenter {
    
    private var searchCallback: DomainsListSearchCallback?
    override var analyticsName: Analytics.ViewName { .homeDomainsSearch }
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var title: String { String.Constants.allDomains.localized() }
    override var isSearchable: Bool { true }
    
    init(view: DomainsListViewProtocol,
         domains: [DomainDisplayInfo],
         searchCallback: @escaping DomainsListSearchCallback) {
        super.init(view: view,
                   domains: domains)
        self.searchCallback = searchCallback
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
            return
        case .domainListItem(let domain, _):
            UDVibration.buttonTap.vibrate()
            logAnalytic(event: .domainPressed, parameters: [.domainName : domain.name])
            view?.cNavigationController?.dismiss(animated: true)
            searchCallback?(domain)
        case .domainsMintingInProgress:
            Debugger.printFailure("Unexpected event", critical: true)
        case .domainSearchItem(let domain, _):
            return 
        }
    }
    
    @MainActor
    override func didSearchWith(key: String) {
        super.didSearchWith(key: key)
        showDomains()
    }
    
    @MainActor
    override func rearrangeButtonPressed() {
        Task {
            guard let view = view?.cNavigationController else { return }
         
            let result = await UDRouter().showNewPrimaryDomainSelectionScreen(domains: domains,
                                                                              isFirstPrimaryDomain: false,
                                                                              shouldPresentModally: false,
                                                                              configuration: .init(shouldAskToSetReverseResolutionIfNotSetYet: false,
                                                                                                   canReverseResolutionETHDomain: false,
                                                                                                   analyticsView: .sortDomainsFromHomeSearch,
                                                                                                   shouldDismissWhenFinished: false),
                                                                              in: view)
            switch result {
            case .cancelled:
                return
            case .domainsOrderSet(let domains):
                await appContext.dataAggregatorService.setDomainsOrder(using: domains)
                self.domains = domains
                showDomains()
            case .domainsOrderAndReverseResolutionSet:
                Debugger.printFailure("Should not be available to set RR from this screen", critical: true)
            }
        }
    }
}

// MARK: - Private methods
private extension DomainsListSearchPresenter {
    @MainActor
    func showDomains() {
        var snapshot = DomainsListSnapshot()
        
        var domains = domains
        var domainsSectionTitle: String?
        if !searchKey.isEmpty {
            domains = domains.filter({ $0.name.lowercased().contains(searchKey) })
            domainsSectionTitle = String.Constants.yourDomains.localized()
            snapshot.appendSections([.globalSearchHint])
            snapshot.appendSections([.dashesSeparator])
        }
        
        if domains.isEmpty {
            snapshot.appendSections([.searchEmptyState])
            snapshot.appendItems([.searchEmptyState])
        } else {
            snapshot.appendSections([.other(title: domainsSectionTitle)])
            snapshot.appendItems(domains.map({ DomainsListViewController.Item.domainListItem($0,
                                                                                             isSelectable: true) }))
        }
        
        view?.applySnapshot(snapshot, animated: true)
    }
}


// MARK: - Private methods
private extension DomainsListSearchPresenter {
    func searchForDomains(searchKey: String) async throws -> [SearchDomainProfile] {
        if searchKey.isValidAddress() {
            let wallet = searchKey
            if let domain = try? await loadGlobalDomainRRInfo(for: wallet) {
                return [domain]
            }
            
            return []
        } else {
            let domains = try await NetworkService().searchForDomainsWith(name: searchKey, shouldBeSetAsRR: false)
            return domains
        }
    }
    
    func loadGlobalDomainRRInfo(for key: String) async throws -> SearchDomainProfile? {
        if let rrInfo = try? await NetworkService().fetchGlobalReverseResolution(for: key.lowercased()),
           rrInfo.name.isUDTLD() {
            
            return SearchDomainProfile(name: rrInfo.name,
                                       ownerAddress: rrInfo.address,
                                       imagePath: rrInfo.pfpURLToUse?.absoluteString,
                                       imageType: .offChain)
        }
        
        return nil
    }
}
