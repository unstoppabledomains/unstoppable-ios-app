//
//  SignTransactionDomainSelectionViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2022.
//

import Foundation
import Combine

@MainActor
protocol SignTransactionDomainSelectionViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: SignTransactionDomainSelectionViewController.Item)
    func didSearchWith(key: String)
    func didStartSearch()
    func didStopSearch()
    func subheadButtonPressed()
}

typealias WalletSelectionCallback = (WalletEntity)->()

@MainActor
final class SignTransactionDomainSelectionViewPresenter: ViewAnalyticsLogger {
    
    private weak var view: SignTransactionDomainSelectionViewProtocol?
    private var selectedWallet: WalletEntity
    private var domains: [DomainDisplayInfo] = []
    private var domainsWithReverseResolution: [DomainDisplayInfo] = []
    private var wallets: [WalletEntity] = []
    private var isSearchActive = false
    private var searchKey = ""
    private var visibleWalletsAddresses: Set<HexAddress> = []
    private var cancellables: Set<AnyCancellable> = []
    
    var domainSelectedCallback: WalletSelectionCallback?
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }
    
    init(view: SignTransactionDomainSelectionViewProtocol,
         selectedWallet: WalletEntity,
         domainSelectedCallback: WalletSelectionCallback?,
         walletsDataService: WalletsDataServiceProtocol) {
        self.view = view
        self.selectedWallet = selectedWallet
        self.domainSelectedCallback = domainSelectedCallback
        walletsDataService.walletsPublisher.receive(on: DispatchQueue.main).sink { [weak self] wallets in
            let domains = wallets.combinedDomains()
            let isDomainsChanged = self?.domains != domains
            if isDomainsChanged {
                self?.domains = domains
                self?.didSearchWith(key: self?.searchKey ?? "")
            }
        }.store(in: &cancellables)
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
            if domainItem.ownerWallet != selectedWallet.address,
               let wallet = wallets.first(where: { $0.isOwningDomain(domainItem.name)}) {
                domainSelectedCallback?(wallet)
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

// MARK: - Private functions
private extension SignTransactionDomainSelectionViewPresenter {
    func prepareData() {
        self.wallets = appContext.walletsDataService.wallets
        domains = wallets.combinedDomains()
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
            if wallets.isEmpty {
                setEmptyState()
            } else {
                let blockchainType = UserDefaults.selectedBlockchainType
                for wallet in wallets {
                    let domains = filter(domains: wallet.domains)
                    if domains.isEmpty {
                        continue
                    }
                    
                    /// Add section for wallet's domains
                    snapshot.appendSections([.walletDomains(wallet: wallet,
                                                            blockchainType: blockchainType)])
                    
                    /// Always show domain with reverse resolution at the top.
                    /// If selected domain is not same as set for reverse resolution, it will be shown as second.
                    let sortedDomains = domains.sorted(by: {
                        if $0 == wallet.rrDomain || $1 == wallet.rrDomain {
                            return $0 == wallet.rrDomain
                        }
                        return $0.name < $1.name
                    })
                    
                    func addCollapsableItemsWith(prefix: Int) {
                        if visibleWalletsAddresses.contains(wallet.address) {
                            snapshot.appendItems(sortedDomains.map({ viewItem(for: $0) }))
                            snapshot.appendItems([.hide(walletAddress: wallet.address)])
                        } else {
                            snapshot.appendItems(sortedDomains.prefix(prefix).map({ viewItem(for: $0) }))
                            snapshot.appendItems([.showOthers(domainsCount: sortedDomains.count - prefix, walletAddress: wallet.address)])
                        }
                    }
                    
                    if isSearchActive {
                        /// If search is active, show all domains in a wallet
                        snapshot.appendItems(sortedDomains.map({ viewItem(for: $0) }))
                    } else {
                        /// If reverse resolution is set for a wallet, by default we show only this domain at the top and 'Show N more' button. If selected domain is not same as set for reverse resolution, it will be shown as second.
                        /// Otherwise show all domains in a wallet.
                        if domains.count == 1 {
                            snapshot.appendItems([viewItem(for: sortedDomains[0])])
                        } else {
                            addCollapsableItemsWith(prefix: 1)
                        }
                    }
                }
            }
        }
        
        view?.applySnapshot(snapshot, animated: animated)
    }
    
    func filter(domains: [DomainDisplayInfo]) -> [DomainDisplayInfo] {
        let key = searchKey
        if key.isEmpty {
            return domains
        } else {
            return domains.filter({ domain in
                domain.name.lowercased().contains(key)
            })
        }
    }
    
    func viewItem(for domain: DomainDisplayInfo) -> SignTransactionDomainSelectionViewController.Item {
        SignTransactionDomainSelectionViewController.Item.domain(domain,
                                                                 isSelected: domain.ownerWallet == selectedWallet.address,
                                                                 isReverseResolutionSet: domainsWithReverseResolution.contains(domain))
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
