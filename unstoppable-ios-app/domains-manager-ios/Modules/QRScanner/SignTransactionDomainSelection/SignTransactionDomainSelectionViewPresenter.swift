//
//  SignTransactionDomainSelectionViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2022.
//

import Foundation

protocol SignTransactionDomainSelectionViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: SignTransactionDomainSelectionViewController.Item)
    func didSearchWith(key: String)
    func didStartSearch()
    func didStopSearch()
    func subheadButtonPressed()
}

typealias DomainWithBalanceSelectionCallback = (DomainDisplayInfo, WalletBalance?)->()

final class SignTransactionDomainSelectionViewPresenter: ViewAnalyticsLogger {
    
    private weak var view: SignTransactionDomainSelectionViewProtocol?
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private var selectedDomain: DomainDisplayInfo
    private var domains: [DomainDisplayInfo] = []
    private var filteredDomains: [DomainDisplayInfo] = []
    private var domainsWithReverseResolution: [DomainDisplayInfo] = []
    private var walletsWithInfo: [WalletWithInfoAndOptionalBalance] = []
    private var isSearchActive = false
    private var searchKey = ""
    private var visibleWalletsAddresses: Set<HexAddress> = []
    var domainSelectedCallback: DomainWithBalanceSelectionCallback?
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }

    init(view: SignTransactionDomainSelectionViewProtocol,
         selectedDomain: DomainDisplayInfo,
         domainSelectedCallback: DomainWithBalanceSelectionCallback?,
         dataAggregatorService: DataAggregatorServiceProtocol) {
        self.view = view
        self.selectedDomain = selectedDomain
        self.domainSelectedCallback = domainSelectedCallback
        self.dataAggregatorService = dataAggregatorService
        dataAggregatorService.addListener(self)
    }
}

// MARK: - SignTransactionDomainSelectionViewPresenterProtocol
extension SignTransactionDomainSelectionViewPresenter: SignTransactionDomainSelectionViewPresenterProtocol {
    func viewDidLoad() {
        Task {
            await prepareData()
            await showData(animated: false)
            await loadData()
            await showData(animated: false)
        }
    }
    
    func didSelectItem(_ item: SignTransactionDomainSelectionViewController.Item) {
        switch item {
        case .domain(let domainItem, _, _):
            logButtonPressedAnalyticEvents(button: .signWCTransactionDomainSelected,
                                           parameters: [.domainName: domainItem.name])
            UDVibration.buttonTap.vibrate()
            if domainItem != selectedDomain,
               let selectedDomainWallet = walletsWithInfo.first(where: { $0.wallet.owns(domain: domainItem) }) {
                domainSelectedCallback?(domainItem, selectedDomainWallet.balance)
            }
            
            Task {
                await view?.dismiss(animated: true)
            }
        case .showOthers(_, let walletAddress):
            set(walletAddress: walletAddress, hidden: false)
        case .hide(let walletAddress):
            set(walletAddress: walletAddress, hidden: true)
        case .emptyState:
            return
        }
    }
    
    func didSearchWith(key: String) {
        Task {
            let lowercasedKey = key.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if key.isEmpty {
                filteredDomains = domains
            } else {
                filteredDomains = domains.filter({ domain in
                    return domain.name.lowercased().contains(lowercasedKey)
                })
            }
            self.searchKey = lowercasedKey
            await showData(animated: true)
        }
    }
    
    func didStartSearch() {
        Task {
            isSearchActive = true
            await showData(animated: true)
        }
    }
    
    func didStopSearch() {
        Task {
            isSearchActive = false
            searchKey = ""
            await showData(animated: true)
        }
    }
    
    func subheadButtonPressed() {
        Task {
            guard let view = self.view else { return }
            
            await appContext.pullUpViewService.showWhatIsReverseResolutionInfoPullUp(in: view)
        }
    }
}

// MARK: - DataAggregatorServiceListener
extension SignTransactionDomainSelectionViewPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        Task {
            switch result {
            case .success(let resultType):
                switch resultType {
                case .domainsUpdated(let domains), .domainsPFPUpdated(let domains):
                    let isDomainsChanged = self.domains != domains
                    if isDomainsChanged {
                        self.domains = domains
                        self.didSearchWith(key: searchKey)
                    }
                case .primaryDomainChanged, .walletsListUpdated:
                    return
                }
            case .failure:
                return
            }
        }
    }
}

// MARK: - Private functions
private extension SignTransactionDomainSelectionViewPresenter {
    func prepareData() async {
        domains = await dataAggregatorService.getDomainsDisplayInfo().interactableItems()
        filteredDomains = domains
        let walletsWithInfo = await dataAggregatorService.getWalletsWithInfo()
        self.walletsWithInfo = walletsWithInfo.map({ WalletWithInfoAndOptionalBalance(wallet: $0.wallet,
                                                                                      displayInfo: $0.displayInfo,
                                                                                      balance: nil)})
        self.domainsWithReverseResolution = walletsWithInfo.compactMap({ $0.displayInfo?.reverseResolutionDomain })
    }
    
    func loadData() async {
        do {
            let walletsWithInfo = try await dataAggregatorService.getWalletsWithInfoAndBalance(for: UserDefaults.selectedBlockchainType)
            self.walletsWithInfo = walletsWithInfo.map({ WalletWithInfoAndOptionalBalance(wallet: $0.wallet,
                                                                                          displayInfo: $0.displayInfo,
                                                                                          balance: $0.balance)})
        } catch {
            await view?.showAlertWith(error: error)
        }
    }
    
    func showData(animated: Bool) async {
        // Fill snapshot
        var snapshot = SignTransactionDomainSelectionSnapshot()
        
        func setEmptyState() {
            snapshot.appendSections([.emptyState])
            snapshot.appendItems([.emptyState])
        }
        
        if isSearchActive,
           searchKey.isEmpty {
            setEmptyState()
        } else {
            var walletsToDomains: [LocalWalletInfo : [DomainDisplayInfo]] = [:]
            
            for walletWithInfo in walletsWithInfo {
                let domains = filteredDomains.filter({ walletWithInfo.wallet.owns(domain: $0) })
                if !domains.isEmpty {
                    let info = LocalWalletInfo(name: walletWithInfo.displayInfo?.displayName ?? "",
                                               address: walletWithInfo.displayInfo?.address ?? "",
                                               balance: walletWithInfo.balance,
                                               selectedDomain: domains.first(where: { $0.name == selectedDomain.name }),
                                               reverseResolutionDomain: walletWithInfo.displayInfo?.reverseResolutionDomain)
                    walletsToDomains[info] = domains
                }
            }
            
            if walletsToDomains.isEmpty {
                setEmptyState()
            } else {
                /// Always show wallet with selected domain at the top
                let sortedInfos = walletsToDomains.map({ $0.key }).sorted(by: {
                    if $0.selectedDomain != nil || $1.selectedDomain != nil {
                        return $0.selectedDomain != nil
                    }
                    return $0.name < $1.name
                })
                
                for info in sortedInfos {
                    /// Add section for wallet's domains
                    snapshot.appendSections([.walletDomains(walletName: info.name,
                                                            walletAddress: info.address,
                                                            balance: info.balance)])
                    
                    let domains = walletsToDomains[info] ?? []
                    /// Always show domain with reverse resolution at the top.
                    /// If selected domain is not same as set for reverse resolution, it will be shown as second.
                    let sortedDomains = domains.sorted(by: {
                        if $0 == info.reverseResolutionDomain || $1 == info.reverseResolutionDomain {
                            return $0 == info.reverseResolutionDomain
                        } else if $0.isSameEntity(selectedDomain) || $1.isSameEntity(selectedDomain) {
                            return $0.isSameEntity(selectedDomain)
                        }
                        
                        return $0.name < $1.name
                    })
                    
                    func addCollapsableItemsWith(prefix: Int) {
                        if visibleWalletsAddresses.contains(info.address) {
                            snapshot.appendItems(sortedDomains.map({ viewItem(for: $0) }))
                            snapshot.appendItems([.hide(walletAddress: info.address)])
                        } else {
                            snapshot.appendItems(sortedDomains.prefix(prefix).map({ viewItem(for: $0) }))
                            snapshot.appendItems([.showOthers(domainsCount: sortedDomains.count - prefix, walletAddress: info.address)])
                        }
                    }
                    
                    if isSearchActive {
                        /// If search is active, show all domains in a wallet
                        snapshot.appendItems(sortedDomains.map({ viewItem(for: $0) }))
                    } else {
                        /// If reverse resolution is set for a wallet, by default we show only this domain at the top and 'Show N more' button. If selected domain is not same as set for reverse resolution, it will be shown as second.
                        /// Otherwise show all domains in a wallet.
                        if let reverseResolutionDomain = info.reverseResolutionDomain {
                            if domains.count == 1 {
                                snapshot.appendItems([viewItem(for: reverseResolutionDomain)])
                            } else if let selectedDomain = info.selectedDomain {
                                if !selectedDomain.isSameEntity(reverseResolutionDomain) {
                                    /// Corner case if there's two domains in a wallet, one with RR and another is selected
                                    if domains.count == 2 {
                                        snapshot.appendItems(sortedDomains.map({ viewItem(for: $0) }))
                                    } else {
                                        addCollapsableItemsWith(prefix: 2)
                                    }
                                } else {
                                    addCollapsableItemsWith(prefix: 1)
                                }
                            } else {
                                addCollapsableItemsWith(prefix: 1)
                            }
                        } else {
                            snapshot.appendItems(sortedDomains.map({ viewItem(for: $0) }))
                        }
                    }
                }
            }
        }
        
        await view?.applySnapshot(snapshot, animated: animated)
    }
    
    func viewItem(for domain: DomainDisplayInfo) -> SignTransactionDomainSelectionViewController.Item {
        SignTransactionDomainSelectionViewController.Item.domain(domain,
                                                                 isSelected: domain.isSameEntity(selectedDomain),
                                                                 isReverseResolutionSet: domainsWithReverseResolution.contains(domain))
    }
    
    struct LocalWalletInfo: Hashable {
        let name: String
        let address: String
        let balance: WalletBalance?
        let selectedDomain: DomainDisplayInfo?
        let reverseResolutionDomain: DomainDisplayInfo?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(address)
        }
        
        static func == (lhs: LocalWalletInfo, rhs: LocalWalletInfo) -> Bool {
            lhs.address == rhs.address
        }
    }
    
    func set(walletAddress: HexAddress, hidden: Bool) {
        Task {
            if hidden {
                visibleWalletsAddresses.remove(walletAddress)
            } else {
                visibleWalletsAddresses.insert(walletAddress)
            }
            await showData(animated: true)
        }
    }
}

private extension SignTransactionDomainSelectionViewPresenter {
    struct WalletWithInfoAndOptionalBalance {
        var wallet: UDWallet
        var displayInfo: WalletDisplayInfo?
        var balance: WalletBalance?
    }
}
