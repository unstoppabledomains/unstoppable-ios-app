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

typealias DomainWithBalanceSelectionCallback = (DomainDisplayInfo)->()

final class SignTransactionDomainSelectionViewPresenter: ViewAnalyticsLogger {
    
    private weak var view: SignTransactionDomainSelectionViewProtocol?
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private var selectedDomain: DomainDisplayInfo
    private var domains: [DomainDisplayInfo] = []
    private var filteredDomains: [DomainDisplayInfo] = []
    private var domainsWithReverseResolution: [DomainDisplayInfo] = []
    private var wallets: [WalletEntity] = []
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
        prepareData()
        showData(animated: false)
    }
    
    func didSelectItem(_ item: SignTransactionDomainSelectionViewController.Item) {
        switch item {
        case .domain(let domainItem, _, _):
            logButtonPressedAnalyticEvents(button: .signWCTransactionDomainSelected,
                                           parameters: [.domainName: domainItem.name])
            UDVibration.buttonTap.vibrate()
            if domainItem != selectedDomain {
                domainSelectedCallback?(domainItem)
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
        let lowercasedKey = key.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty {
            filteredDomains = domains
        } else {
            filteredDomains = domains.filter({ domain in
                return domain.name.lowercased().contains(lowercasedKey)
            })
        }
        self.searchKey = lowercasedKey
        showData(animated: true)
    }
    
    func didStartSearch() {
        isSearchActive = true
        showData(animated: true)
    }
    
    func didStopSearch() {
        isSearchActive = false
        searchKey = ""
        showData(animated: true)
    }
    
    func subheadButtonPressed() {
        guard let view = self.view else { return }
        
        appContext.pullUpViewService.showWhatIsReverseResolutionInfoPullUp(in: view)
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
    func prepareData() {
        self.wallets = appContext.walletsDataService.wallets
        domains = wallets.reduce([DomainDisplayInfo](), { $0 + $1.domains })
        filteredDomains = domains
        domainsWithReverseResolution = wallets.compactMap({ $0.rrDomain })
    }
    
    func showData(animated: Bool) {
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
            
            for walletWithInfo in wallets {
                let domains = filteredDomains.filter({ walletWithInfo.udWallet.owns(domain: $0) })
                if !domains.isEmpty {
                    let info = LocalWalletInfo(wallet: walletWithInfo,
                                               name: walletWithInfo.displayName,
                                               address: walletWithInfo.address,
                                               selectedDomain: domains.first(where: { $0.name == selectedDomain.name }),
                                               reverseResolutionDomain: walletWithInfo.rrDomain)
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
                let blockchainType = UserDefaults.selectedBlockchainType
                for info in sortedInfos {
                    /// Add section for wallet's domains
                    snapshot.appendSections([.walletDomains(wallet: info.wallet,
                                                            blockchainType: blockchainType)])
                    
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
        
        view?.applySnapshot(snapshot, animated: animated)
    }
    
    func viewItem(for domain: DomainDisplayInfo) -> SignTransactionDomainSelectionViewController.Item {
        SignTransactionDomainSelectionViewController.Item.domain(domain,
                                                                 isSelected: domain.isSameEntity(selectedDomain),
                                                                 isReverseResolutionSet: domainsWithReverseResolution.contains(domain))
    }
    
    struct LocalWalletInfo: Hashable {
        let wallet: WalletEntity
        let name: String
        let address: String
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
        if hidden {
            visibleWalletsAddresses.remove(walletAddress)
        } else {
            visibleWalletsAddresses.insert(walletAddress)
        }
        showData(animated: true)
    }
}
