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
    
    typealias SearchProfilesTask = Task<[SearchDomainProfile], Error>
    private let debounce: TimeInterval = 0.3
    private var currentTask: SearchProfilesTask?
    private var globalProfiles: [SearchDomainProfile] = []
    private var isLoadingGlobalProfiles = false
    
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
            logAnalytic(event: .domainPressed, parameters: [.domainName : domain.name,
                                                            .isUserDomain : String(false)])
            view?.cNavigationController?.dismiss(animated: true)
            searchCallback?(domain)
        case .domainsMintingInProgress:
            Debugger.printFailure("Unexpected event", critical: true)
        case .domainSearchItem(let searchProfile, _):
            UDVibration.buttonTap.vibrate()
            view?.hideKeyboard()
            logAnalytic(event: .domainPressed, parameters: [.domainName : searchProfile.name,
                                                            .isUserDomain : String(true)])
            guard let walletAddress = searchProfile.ownerAddress,
                  let domainDisplayInfo = domains.first,
                  let view else { return }
            let domain = domainDisplayInfo.toDomainItem()
            let domainPublicInfo = PublicDomainDisplayInfo(walletAddress: walletAddress, name: searchProfile.name)
            UDRouter().showPublicDomainProfile(of: domainPublicInfo,
                                               viewingDomain: domain,
                                               preRequestedAction: nil,
                                               in: view)
        }
    }
    
    @MainActor
    override func didSearchWith(key: String) {
        super.didSearchWith(key: key)
        globalProfiles.removeAll()
        scheduleSearchGlobalProfiles()
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
        
        if domains.isEmpty && globalProfiles.isEmpty && !isLoadingGlobalProfiles {
            snapshot.appendSections([.searchEmptyState])
            snapshot.appendItems([.searchEmptyState])
        }
        
        if !domains.isEmpty {
            snapshot.appendSections([.other(title: domainsSectionTitle)])
            snapshot.appendItems(domains.map({ DomainsListViewController.Item.domainListItem($0,
                                                                                             isSelectable: true) }))
        }
        
        if !globalProfiles.isEmpty {
            snapshot.appendSections([.other(title: String.Constants.globalSearch.localized())])
            snapshot.appendItems(globalProfiles.map({ DomainsListViewController.Item.domainSearchItem($0, isSelectable: true) }))
        }
        
        view?.applySnapshot(snapshot, animated: true)
    }
}

// MARK: - Private methods
private extension DomainsListSearchPresenter {
    func scheduleSearchGlobalProfiles() {
        let searchKey = self.searchKey
        isLoadingGlobalProfiles = true
        Task {
            do {
                let profiles = try await searchForGlobalProfiles(with: searchKey)
                let userDomains = Set(self.domains.map({ $0.name }))
                self.globalProfiles = profiles.filter({ !userDomains.contains($0.name) && $0.ownerAddress != nil })
                showDomains()
            }
            isLoadingGlobalProfiles = false
        }
    }
    
    func searchForGlobalProfiles(with searchKey: String) async throws -> [SearchDomainProfile] {
        // Cancel previous search task if it exists
        currentTask?.cancel()
        
        let debounce = self.debounce
        let task: SearchProfilesTask = Task.detached {
            do {
                await Task.sleep(seconds: debounce)
                try Task.checkCancellation()
                
                let profiles = try await self.searchForDomains(searchKey: searchKey)
                
                try Task.checkCancellation()
                return profiles
            } catch NetworkLayerError.requestCancelled, is CancellationError {
                return []
            } catch {
                throw error
            }
        }
        
        currentTask = task
        let users = try await task.value
        return users
    }
    
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
