//
//  WalletDetailsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.05.2022.
//

import UIKit

@MainActor
protocol WalletDetailsViewPresenterProtocol: BasePresenterProtocol {
    var walletAddress: String { get }
    func didSelectItem(_ item: WalletDetailsViewController.Item)
}

final class WalletDetailsViewPresenter: ViewAnalyticsLogger {
    
    private weak var view: WalletDetailsViewProtocol?
    private var wallet: UDWallet
    private var walletInfo: WalletDisplayInfo
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private let networkReachabilityService: NetworkReachabilityServiceProtocol?
    private let udWalletsService: UDWalletsServiceProtocol
    private let walletConnectClientService: WalletConnectClientServiceProtocol
    private let walletConnectServiceV2: WalletConnectServiceV2Protocol
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }
    var walletRemovedCallback: EmptyCallback?
    
    init(view: WalletDetailsViewProtocol,
         wallet: UDWallet,
         walletInfo: WalletDisplayInfo,
         dataAggregatorService: DataAggregatorServiceProtocol,
         networkReachabilityService: NetworkReachabilityServiceProtocol?,
         udWalletsService: UDWalletsServiceProtocol,
         walletConnectClientService: WalletConnectClientServiceProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol) {
        self.view = view
        self.wallet = wallet
        self.walletInfo = walletInfo
        self.dataAggregatorService = dataAggregatorService
        self.networkReachabilityService = networkReachabilityService
        self.udWalletsService = udWalletsService
        self.walletConnectClientService = walletConnectClientService
        self.walletConnectServiceV2 = walletConnectServiceV2
    }
}

// MARK: - WalletDetailsViewPresenterProtocol
extension WalletDetailsViewPresenter: WalletDetailsViewPresenterProtocol {
    var walletAddress: String { wallet.address }
    
    func viewDidLoad() {
        dataAggregatorService.addListener(self)
        networkReachabilityService?.addListener(self)
        showWalletDetails()
    }
    
    func viewDidAppear() {
        updateTitle()
    }
    
    @MainActor
    func didSelectItem(_ item: WalletDetailsViewController.Item) {
        Task {
            guard let view = self.view else { return }
            
            switch item {
            case .listItem(let listItem):
                logButtonPressedAnalyticEvents(button: listItem.analyticsName)
                UDVibration.buttonTap.vibrate()
                switch listItem {
                case .removeWallet:
                    askToRemoveWallet()
                case .recoveryPhrase(let recoveryType):
                    revealRecoveryPhrase(recoveryType: recoveryType)
                case .rename:
                    showRenameWalletScreen()
                case .backUp(let state, let isOnline):
                    guard isOnline else { return }
                    
                    switch state {
                    case .backedUp:
                        return
                    case .importedNotBackedUp, .locallyGeneratedNotBackedUp:
                        showBackupWalletScreenIfAvailable()
                    }
                case .domains:
                    await showWalletDomains()
                case .reverseResolution(let state):
                    switch state {
                    case .notSet:
                        let result = await UDRouter().runSetupReverseResolutionFlow(in: view,
                                                                                    for: wallet,
                                                                                    walletInfo: walletInfo,
                                                                                    mode: .chooseFirstDomain)
                        handleSetupReverseResolution(result: result)
                    case .setFor(let domain, _, _):
                        let result = await UDRouter().runSetupReverseResolutionFlow(in: view,
                                                                                    for: wallet,
                                                                                    walletInfo: walletInfo,
                                                                                    mode: .changeDomain(currentDomain: domain))
                        handleSetupReverseResolution(result: result)
                    case .settingFor(let domainDisplayInfo):
                        showReverseResolutionInProgress(for: domainDisplayInfo)
                    }
                case .importWallet:
                    importExternalWallet()
                }
            case .topInfo:
                return
            }
        }
    }
}

// MARK: - DataResolutionServiceListener
extension WalletDetailsViewPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        if case .success(let resultType) = result {
            switch resultType {
            case .walletsListUpdated(let walletsWithInfo):
                if let walletWithInfo = walletsWithInfo.first(where: { $0.wallet == wallet }),
                   let walletInfo = walletWithInfo.displayInfo {
                    self.wallet = walletWithInfo.wallet
                    self.walletInfo = walletInfo
                    showWalletDetails()
                } else {
                    Task { await MainActor.run { view?.cNavigationController?.popViewController(animated: true) } }
                }
            case .domainsUpdated, .primaryDomainChanged, .domainsPFPUpdated:
                return
            }
        }
    }
}

// MARK: - NetworkReachabilityServiceListener
extension WalletDetailsViewPresenter: NetworkReachabilityServiceListener {
    func networkStatusChanged(_ status: NetworkReachabilityService.Status) {
        DispatchQueue.main.async { [weak self] in
            self?.showWalletDetails()
        }
    }
}

// MARK: - Private functions
private extension WalletDetailsViewPresenter {
    func showWalletDetails() {
        Task {
            var snapshot = WalletDetailsSnapshot()
            let isReverseResolutionChangeAllowed = await dataAggregatorService.isReverseResolutionChangeAllowed(for: wallet)
            
            let rrDomain = await dataAggregatorService.reverseResolutionDomain(for: wallet)
            var isRRSetupInProgress = false
            if let rrDomain = rrDomain {
                isRRSetupInProgress = await dataAggregatorService.isReverseResolutionSetupInProgress(for: rrDomain.name)
            }
            let isExternalWallet: Bool
            switch walletInfo.source {
            case .locallyGenerated, .imported:
                isExternalWallet = false
            case .external:
                isExternalWallet = true
            }
            
            // Top info
            snapshot.appendSections([.topInfo])
            snapshot.appendItems([.topInfo(.init(walletInfo: walletInfo,
                                                 domain: rrDomain,
                                                 isUpdating: isRRSetupInProgress,
                                                 copyButtonPressed: { [weak self] in self?.copyAddressButtonPressed() },
                                                 externalBadgePressed: { [weak self] in self?.externalBadgePressed() }))])
            let isNetworkReachable = networkReachabilityService?.isReachable == true
            // Backup and recovery phrase
            if !isExternalWallet {
                snapshot.appendSections([.backUpAndRecovery])
                snapshot.appendItems([.listItem(.backUp(state: walletInfo.backupState,
                                                        isOnline: isNetworkReachable))])
                if let recoveryType = UDWallet.RecoveryType(walletType: wallet.type) {
                    snapshot.appendItems([.listItem(.recoveryPhrase(recoveryType: recoveryType))])
                }
            }
            
            // Rename, Reverse Resolution and domains
            snapshot.appendSections([.renameAndDomains])
            snapshot.appendItems([.listItem(.rename)])
            
            if let rrDomain = rrDomain {
                if isRRSetupInProgress {
                    snapshot.appendItems([.listItem(.reverseResolution(state: .settingFor(domain: rrDomain)))])
                } else {
                    if walletInfo.domainsCount == 1 {
                        // For single domain there's no reason to show updating records state since user can't change it. 
                        snapshot.appendItems([.listItem(.reverseResolution(state: .setFor(domain: rrDomain, isEnabled: false, isUpdatingRecords: false)))])
                    } else {
                        snapshot.appendItems([.listItem(.reverseResolution(state: .setFor(domain: rrDomain,
                                                                                          isEnabled: isReverseResolutionChangeAllowed,
                                                                                          isUpdatingRecords: !isReverseResolutionChangeAllowed)))])
                    }
                }
            } else {
                if walletInfo.domainsCount > 0 {
                    snapshot.appendItems([.listItem(.reverseResolution(state: .notSet(isEnabled: isReverseResolutionChangeAllowed)))])
                }
            }
            
            if walletInfo.domainsCount > 0 {
                snapshot.appendItems([.listItem(.domains(domainsCount: walletInfo.domainsCount,
                                                         walletName: walletInfo.walletSourceName))])
            }
            
            // Remove wallet
            snapshot.appendSections([.removeWallet])
            if isExternalWallet {
                snapshot.appendItems([.listItem(.importWallet)])
            }
            snapshot.appendItems([.listItem(.removeWallet(isConnected: walletInfo.isConnected,
                                                          walletName: walletInfo.walletSourceName))])
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
    
    @MainActor
    func revealRecoveryPhrase(recoveryType: UDWallet.RecoveryType) {
        guard let view = self.view else { return }
        
        let wallet = self.wallet
        Task {
            do {
                try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                UDRouter().showRecoveryPhrase(of: wallet,
                                              recoveryType: recoveryType,
                                              in: view,
                                              dismissCallback: {
                    AppReviewService.shared.appReviewEventDidOccurs(event: .didRevealPK)
                })
            }
        }
    }
    
    @MainActor
    func askToRemoveWallet() {
        guard let view = self.view else { return }
        Task {
            do {
                try await appContext.pullUpViewService.showRemoveWalletPullUp(in: view, walletInfo: walletInfo)
                await view.dismissPullUpMenu()
                try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                await removeWallet()
                walletRemovedCallback?()
            }
        }
    }
    
    @MainActor
    func indicateWalletRemoved() {
        if wallet.walletState == .externalLinked {
            appContext.toastMessageService.showToast(.walletDisconnected, isSticky: false)
        } else {
            appContext.toastMessageService.showToast(.walletRemoved(walletName: walletInfo.walletSourceName), isSticky: false)
        }
    }
    
    func removeWallet() async {
        udWalletsService.remove(wallet: wallet)
        // WC1 + WC2
        try? walletConnectClientService.disconnect(walletAddress: wallet.address)
        await walletConnectServiceV2.disconnect(from: wallet.address)
        let wallets = udWalletsService.getUserWallets()
        guard !wallets.isEmpty else { return }
        await indicateWalletRemoved()
    }
    
    func copyAddressButtonPressed() {
        logButtonPressedAnalyticEvents(button: .copyWalletAddress)
        CopyWalletAddressPullUpHandler.copyToClipboard(address: wallet.address, ticker: BlockchainType.Ethereum.rawValue)
    }
 
    func externalBadgePressed() {
        guard let view = self.view else { return }

        logButtonPressedAnalyticEvents(button: .showConnectedWalletInfo)
        Task {
            await appContext.pullUpViewService.showConnectedWalletInfoPullUp(in: view)
        }
    }
    
    @MainActor
    func showRenameWalletScreen() {
        guard let view = self.view else { return }

        UDRouter().showRenameWalletScreen(of: wallet,
                                          walletDisplayInfo: walletInfo,
                                          nameUpdatedCallback: { [weak self] updatedWallet in
            self?.updateWalletData(updatedWallet)
        },
                                          in: view)
    }
    
    @MainActor
    func showBackupWalletScreenIfAvailable() {
        guard let view = self.view else { return }

        guard iCloudWalletStorage.isICloudAvailable() else {
            view.showICloudDisabledAlert()
            return
        }
        
        UDRouter().showBackupWalletScreen(for: wallet, walletBackedUpCallback: { [weak self] updatedWallet in
            self?.updateWalletData(updatedWallet)
            self?.updateTitle()
            AppReviewService.shared.appReviewEventDidOccurs(event: .walletBackedUp)
        }, in: view)
    }
    
    func updateWalletData(_ updatedWallet: UDWallet) {
        Task {
            guard let newWalletInfo = await dataAggregatorService.getWalletDisplayInfo(for: updatedWallet) else { return }
            
            self.wallet = updatedWallet
            self.walletInfo = newWalletInfo
            self.showWalletDetails()
        }
    }
    
    func showWalletDomains() async {
        guard let view = self.view else { return }
        
        let domains = await dataAggregatorService.getDomainsDisplayInfo().filter({ $0.isOwned(by: wallet) })
        await UDRouter().showWalletDomains(domains,
                                           walletWithInfo: WalletWithInfo(wallet: wallet, displayInfo: walletInfo),
                                           in: view)
    }
    
    func updateTitle() {
        Task {
            await view?.set(title: walletInfo.displayName)
        }
    }
    
    func handleSetupReverseResolution(result: SetupWalletsReverseResolutionNavigationManager.Result) {
        switch result {
        case .cancelled:
            return
        case .set:
            showWalletDetails()
        }
    }
    
    @MainActor
    func importExternalWallet() {
        guard let view = self.view else { return }
        
        UDRouter().showImportExistingExternalWalletModule(in: view,
                                                          externalWalletInfo: walletInfo) { [weak self] wallet in
            self?.didImportExternalWallet(wallet)
        }
    }
    
    func didImportExternalWallet(_ wallet: UDWallet) {
        self.view?.presentedViewController?.dismiss(animated: true)
        self.wallet = wallet
        self.walletInfo = WalletDisplayInfo(wallet: wallet,
                                            domainsCount: self.walletInfo.domainsCount,
                                            udDomainsCount: self.walletInfo.domainsCount) ?? self.walletInfo
        showWalletDetails()
    }
    
    @MainActor
    func showReverseResolutionInProgress(for domainDisplayInfo: DomainDisplayInfo) {
        Task {
            guard let view = self.view else { return }

            do {
                let domain = try await dataAggregatorService.getDomainWith(name: domainDisplayInfo.name)
                UDRouter().showReverseResolutionInProgressScreen(in: view,
                                                                 domain: domain,
                                                                 domainDisplayInfo: domainDisplayInfo,
                                                                 walletInfo: walletInfo)
            }
        }
    }
}
