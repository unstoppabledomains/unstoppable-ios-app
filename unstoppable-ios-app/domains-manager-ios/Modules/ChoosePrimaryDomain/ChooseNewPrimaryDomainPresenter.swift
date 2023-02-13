//
//  ChooseFirstPrimaryDomainPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2022.
//

import UIKit

typealias DomainItemSelectedCallback = (SetNewHomeDomainResult)->()

enum SetNewHomeDomainResult {
    case cancelled
    case domainsOrderSet(_ domains: [DomainDisplayInfo])
    case domainsOrderAndReverseResolutionSet(_ domains: [DomainDisplayInfo], reverseResolutionDomain: DomainDisplayInfo)
}

final class ChooseNewPrimaryDomainPresenter: ChoosePrimaryDomainViewPresenter {
    
    private var domains: [DomainDisplayInfo]
    private let configuration: Configuration
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private var walletsWithInfo: [WalletWithInfo] = []
    var resultCallback: DomainItemSelectedCallback?
    override var analyticsName: Analytics.ViewName { configuration.analyticsView }
    
    init(view: ChoosePrimaryDomainViewProtocol,
         domains: [DomainDisplayInfo],
         configuration: Configuration,
         dataAggregatorService: DataAggregatorServiceProtocol,
         resultCallback: @escaping DomainItemSelectedCallback) {
        self.domains = domains
        self.configuration = configuration
        self.dataAggregatorService = dataAggregatorService
        super.init(view: view)
        self.resultCallback = resultCallback
    }
    
    @MainActor
    override func viewDidLoad() {
        Task {
            setConfirmButton()
            setupView()
            await showData()
        }
    }
    
    @MainActor
    override func didSelectItem(_ item: ChoosePrimaryDomainViewController.Item) {
        guard isSearchActive else { return }
        
        switch item {
        case .domain(let domain, let rrInfo, _):
            logAnalytic(event: .domainPressed, parameters: [.domainName : domain.name])
            stopSearchAndScroll(to: domain, rrInfo: rrInfo)
        case .domainName, .header, .searchEmptyState:
            return
        }
    }
    
    override func confirmButtonPressed() {
        Task {
            guard let primaryDomain = domains.first,
                  let nav = await view?.cNavigationController else { return }
            
            saveDomainsOrder()
            if primaryDomain.isSetForRR || !configuration.shouldAskToSetReverseResolutionIfNotSetYet {
                await finish(result: .domainsOrderSet(domains))
            } else {                
                // Do not ask to set RR for domains on ETH
                if !configuration.canReverseResolutionETHDomain,
                   primaryDomain.blockchain != .Matic {
                    await finish(result: .domainsOrderSet(domains))
                    return
                }
                
                if !(await dataAggregatorService.isReverseResolutionChangeAllowed(for: primaryDomain)) {
                    await finish(result: .domainsOrderSet(domains))
                    return
                }
                
                guard let walletWithInfo = walletsWithInfo.first(where: { primaryDomain.isOwned(by: $0.wallet) }),
                      let displayInfo = walletWithInfo.displayInfo,
                      let resultCallback = self.resultCallback else {
                    Debugger.printFailure("Failed to find wallet for selected home screen domain")
                    await finish(result: .domainsOrderSet(domains))
                    return
                }
                
                saveDomainsOrder()
                await UDRouter().showSetupNewReverseResolutionModule(in: nav,
                                                                     wallet: walletWithInfo.wallet,
                                                                     walletInfo: displayInfo,
                                                                     domains: self.domains,
                                                                     reverseResolutionDomain: primaryDomain,
                                                                     resultCallback: resultCallback)
            }
        }
    }
   
    override func didMoveItem(from fromIndex: Int, to toIndex: Int) {
        if fromIndex < 0 || toIndex >= domains.count {
            Debugger.printFailure("Did move domains out of range")
            showDataAsync()
            return
        }

        let movedDomain = domains[fromIndex]
        domains.remove(at: fromIndex)
        domains.insert(movedDomain, at: toIndex)
        logAnalytic(event: .domainMoved, parameters: [.domainName : movedDomain.name])
    }
    
    @MainActor
    override func didSearchWith(key: String) {
        super.didSearchWith(key: key)
        showDataAsync()
    }
    
    @MainActor
    override func didStartSearch() {
        super.didStartSearch()
        
        view?.setTitleHidden(true)
        showDataAsync()
    }
    
    @MainActor
    override func didStopSearch() {
        super.didStopSearch()
        
        view?.setTitleHidden(false)
        showDataAsync()
    }
}

// MARK: - Private functions
private extension ChooseNewPrimaryDomainPresenter {
    @MainActor
    func stopSearchAndScroll(to domain: DomainDisplayInfo, rrInfo: WalletDisplayInfo?) {
        view?.stopSearching()
        super.didStopSearch()
        view?.setTitleHidden(false)
        Task {
            await showData()
            try? await Task.sleep(seconds: 0.3)
            view?.scrollTo(item: .domain(domain, reverseResolutionWalletInfo: rrInfo, isSearching: false))
        }
    }
    
    func showDataAsync() {
        Task { await showData() }
    }
    
    func showData() async {
        walletsWithInfo = await dataAggregatorService.getWalletsWithInfo()
        let walletsWithRR = walletsWithInfo.filter({ $0.displayInfo?.reverseResolutionDomain != nil })

        var snapshot = ChoosePrimaryDomainSnapshot()
        var domains = self.domains
        
        func addDomainsListToSnapshot() {
            snapshot.appendSections([.allDomains])
            snapshot.appendItems(domains.map({ domain in
                let walletWithInfo = walletsWithRR.first(where: { $0.displayInfo?.reverseResolutionDomain?.isSameEntity(domain) == true })
                let displayInfo = walletWithInfo?.displayInfo
                return ChoosePrimaryDomainViewController.Item.domain(domain,
                                                                     reverseResolutionWalletInfo: displayInfo,
                                                                     isSearching: isSearchActive)
            }))
        }
                
        if isSearchActive {
            if !searchKey.isEmpty {
                domains = domains.filter({ $0.name.lowercased().contains(searchKey.lowercased()) })
                if domains.isEmpty {
                    snapshot.appendSections([.searchEmptyState])
                    snapshot.appendItems([.searchEmptyState(mode: .noResults)])
                } else {
                    addDomainsListToSnapshot()
                }
            } else {
                snapshot.appendSections([.searchEmptyState])
                snapshot.appendItems([.searchEmptyState(mode: .searchStarted)])
            }
        } else {
            snapshot.appendSections([.header])
            snapshot.appendItems([.header])
            addDomainsListToSnapshot()
        }
        
        await view?.applySnapshot(snapshot, animated: true)
    }
    
    @MainActor
    func setConfirmButton() {
        view?.setConfirmButtonTitle(String.Constants.confirm.localized())
        view?.setConfirmButtonEnabled(true)
    }
    
    @MainActor
    func setupView() {
        view?.setDashesProgress(nil)
    }
    
    func finish(result: SetNewHomeDomainResult) async {
        if configuration.shouldDismissWhenFinished {
            await view?.cNavigationController?.dismiss(animated: true)
        } else {
            await view?.cNavigationController?.popViewController(animated: true)
        }
        resultCallback?(result)
    }
    
    func saveDomainsOrder() {
        for i in 0..<domains.count {
            domains[i].setOrder(i)
        }
    }
}

// MARK: - Configuration
extension ChooseNewPrimaryDomainPresenter {
    struct Configuration {
        var shouldAskToSetReverseResolutionIfNotSetYet: Bool = true
        let canReverseResolutionETHDomain: Bool
        let analyticsView: Analytics.ViewName
        var shouldDismissWhenFinished: Bool = true
    }
}
