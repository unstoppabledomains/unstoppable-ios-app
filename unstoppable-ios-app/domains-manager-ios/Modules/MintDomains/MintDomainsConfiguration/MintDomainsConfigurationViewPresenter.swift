//
//  MintDomainsConfigurationViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import Foundation

protocol MintDomainsConfigurationViewPresenterProtocol: BasePresenterProtocol {
    var domainsCount: Int { get }
    var progress: Double? { get }
    var title: String { get }
    func didSelectItem(_ item: MintDomainsConfigurationViewController.Item)
    func walletSelectorButtonPressed()
    func mintDomainsButtonPressed()
}

final class MintDomainsConfigurationViewPresenter: ViewAnalyticsLogger {
    
    private weak var view: MintDomainsConfigurationViewProtocol?
    private weak var mintDomainsFlowManager: MintDomainsFlowManager?
    private let unMintedDomains: [String]
    private var unMintedAvailableDomains: [String] = []
    private let mintedDomains: [DomainItem]
    private let walletsService: UDWalletsServiceProtocol
    private var wallets = [UDWallet]()
    private var selectedWallet: UDWallet?
    private var selectedDomains: Set<String> = []
    private var shouldUseAsPrimary = false
    private let mintDomainsAmountLimit = 50
    var progress: Double? { 0.75 }
    var title: String { String.Constants.pluralMintDomains.localized(unMintedDomains.count) }
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }

    init(view: MintDomainsConfigurationViewProtocol,
         unMintedDomains: [String],
         mintedDomains: [DomainItem],
         mintDomainsFlowManager: MintDomainsFlowManager,
         walletsService: UDWalletsServiceProtocol) {
        self.view = view
        self.unMintedDomains = unMintedDomains
        self.mintedDomains = mintedDomains
        self.mintDomainsFlowManager = mintDomainsFlowManager
        self.walletsService = walletsService
        self.unMintedAvailableDomains = unMintedDomains.filter({ !isDomainNameDeprecated($0) })
    }
    
}

// MARK: - MintDomainsConfigurationViewPresenterProtocol
extension MintDomainsConfigurationViewPresenter: MintDomainsConfigurationViewPresenterProtocol {
    func viewDidLoad() {
        shouldUseAsPrimary = !alreadyHasDomains
        Task {
            await MainActor.run {
                view?.setDashesProgress(0.75)
            }
            await checkLimitReached()
            await updateMintButton()
            await loadData()
            await showDomainsToSelect()
        }
    }
    
    var domainsCount: Int { unMintedDomains.count }

    func didSelectItem(_ item: MintDomainsConfigurationViewController.Item) {
        Task {
            switch item {
            case .domainListItem(let configuration):
                guard configuration.state == .normal || configuration.isSelected else { return }
                
                let domain = configuration.domain
                UDVibration.buttonTap.vibrate()
                if configuration.isSelected {
                    selectedDomains.remove(domain)
                    logAnalytic(event: .didDeselectDomain, parameters: [.domains : String(selectedDomains.count)])
                } else {
                    selectedDomains.insert(domain)
                    logAnalytic(event: .didSelectDomain, parameters: [.domains : String(selectedDomains.count)])
                }
                await showDomainsToSelect()
                await updateMintButton()
                await checkLimitReached()
            case .domainCard, .setPrimary, .header:
                return
            }
        }
    }
    
    func walletSelectorButtonPressed() {
        Task {
            guard let view = self.view else { return }
                    
            do {
                self.selectedWallet = try await UDRouter().showWalletSelectionToMintDomainsScreen(selectedWallet: selectedWallet, in: view)
                await updateUIForSelectedWallet()
            }
        }
    }
    
    func mintDomainsButtonPressed() {
        logButtonPressedAnalyticEvents(button: .mintDomains, parameters: [.count : String(selectedDomains.count)])

        Task {
            guard let wallet = self.selectedWallet else {
                Debugger.printFailure("Couldn't get wallet", critical: true)
                return
            }
            await view?.setLoadingIndicator(active: true)
            do {
                if unMintedDomains.count > 1 {
                    try await mintDomainsFlowManager?.handle(action: .didSelectDomainsToMint(Array(selectedDomains), wallet: wallet))
                } else if let domain = unMintedAvailableDomains.first {
                    try await mintDomainsFlowManager?.handle(action: .didSelectDomainToMint(domain, wallet: wallet, isPrimary: shouldUseAsPrimary))
                }
                await view?.setLoadingIndicator(active: false)
            } catch {
                await MainActor.run {
                    view?.setLoadingIndicator(active: false)
                    view?.showAlertWith(error: error, handler: nil)
                }
            }
        }
    }
}

// MARK: - Private functions
private extension MintDomainsConfigurationViewPresenter {
    var alreadyHasDomains: Bool { !mintedDomains.isEmpty }
    var isAllSelected: Bool { selectedDomains.count == unMintedAvailableDomains.count || selectedDomains.count == mintDomainsAmountLimit }
    var isOverLimit: Bool { selectedDomains.count >= mintDomainsAmountLimit }
    
    func showDomainsToSelect(animated: Bool = false) async {
        guard !unMintedDomains.isEmpty else {
            Debugger.printFailure("No domains to mint", critical: true)
            return
        }
        var snapshot = MintDomainsConfigurationSnapshot()
        let isSingleDeprecatedDomainInList = unMintedDomains.count == 1 && isDomainNameDeprecated(unMintedDomains[0])
        if unMintedDomains.count > 1 || isSingleDeprecatedDomainInList {
            snapshot.appendSections([.domainsList(domainsCount: unMintedDomains.count,
                                                  isAllSelected: unMintedAvailableDomains.isEmpty ? false : isAllSelected,
                                                  selectAllButtonCallback: { [weak self] in self?.didSelectAllButtonPressed() })])
            snapshot.appendItems(unMintedDomains.map({ domainName in
                
                var state: MintDomainsConfigurationSelectionCell.State = .normal
                if isDomainNameDeprecated(domainName) {
                    state = .deprecated
                } else if isOverLimit && !selectedDomains.contains(domainName) {
                    state = .disabled
                }
                
                return MintDomainsConfigurationViewController.Item.domainListItem(configuration: .init(domain: domainName,
                                                                                                                                       isSelected: selectedDomains.contains(domainName),
                                                                                                                                       state: state))
                
            }))
        } else {
            snapshot.appendSections([.domainCard])
            snapshot.appendItems([.domainCard(unMintedDomains[0])])
            snapshot.appendItems([.setPrimary(isSelected: shouldUseAsPrimary,
                                              isEnabled: alreadyHasDomains,
                                              infoPressedCallback: { [weak self] in
                self?.logButtonPressedAnalyticEvents(button: .primaryDomainInfo)
                self?.showPrimaryDomainInfo()
            },
                                              valueChangedCallback: { [weak self] isOn in
                self?.logButtonPressedAnalyticEvents(button: .setAsPrimary,
                                                     parameters: [.isOn : String(isOn)])
                self?.setShouldUseAsPrimary(isOn)
            })])
        }
        
        await view?.applySnapshot(snapshot, animated: animated)
        if unMintedDomains.count == 1 {
            await view?.setScrollEnabled(false)
        }
    }
    
    @MainActor
    func checkLimitReached() {
        view?.setMintingLimitReached(visible: isOverLimit, limit: mintDomainsAmountLimit)
    }
    
    func loadData() async {
        wallets = walletsService.getUserWallets()
        selectedWallet = wallets.first
        await updateUIForSelectedWallet()
    }
    
    @MainActor
    func updateUIForSelectedWallet() {
        guard let selectedWallet = self.selectedWallet,
            let walletInfo = WalletDisplayInfo(wallet: selectedWallet, domainsCount: 0) else { return }
        
        view?.setWalletInfo(walletInfo, canSelect: wallets.count > 1)
    }
    
    @MainActor
    func updateMintButton() {
        if unMintedDomains.count > 1 {
            view?.setMintButtonEnabled(!selectedDomains.isEmpty)
        } else {
            view?.setMintButtonEnabled(!unMintedAvailableDomains.isEmpty)
        }
    }
    
    func didSelectAllButtonPressed() {
        Task {
            if isAllSelected {
                logButtonPressedAnalyticEvents(button: .deselectAll)
                selectedDomains.removeAll()
            } else {
                logButtonPressedAnalyticEvents(button: .selectAll)
                if unMintedAvailableDomains.count <= mintDomainsAmountLimit {
                    selectedDomains = Set(unMintedAvailableDomains)
                } else {
                    for domain in unMintedAvailableDomains where !selectedDomains.contains(domain) {
                        guard !isOverLimit else { break }
                        
                        selectedDomains.insert(domain)
                    }
                }
            }
            await showDomainsToSelect()
            await updateMintButton()
            await checkLimitReached()
        }
    }
    
    func showPrimaryDomainInfo() {
        Task {
            guard let view = self.view else { return }
            
            await appContext.pullUpViewService.showWhatIsPrimaryDomainInfoPullUp(in: view)
        }
    }
    
    func setShouldUseAsPrimary(_ shouldUseAsPrimary: Bool) {
        Task {
            self.shouldUseAsPrimary = shouldUseAsPrimary
            await showDomainsToSelect()
        }
    }
    
    func isDomainNameDeprecated(_ domainName: DomainName) -> Bool {
        guard let tld = domainName.getTldName() else {
            Debugger.printFailure("Not a domain name", critical: true)
            return false
        }
        
        return Constants.deprecatedTLDs.contains(tld)
    }
}
