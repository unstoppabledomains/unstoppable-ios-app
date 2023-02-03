//
//  NewWalletsListViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2022.
//

import UIKit

protocol WalletsListViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var title: String { get }
    var canAddWallet: Bool { get }

    func didPressAddButton()
    func didSelectItem(_ item: WalletsListViewController.Item)
}

class WalletsListViewPresenter {
    
    private(set) weak var view: WalletsListViewProtocol?
    
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private let networkReachabilityService: NetworkReachabilityServiceProtocol?
    private let udWalletsService: UDWalletsServiceProtocol
    private var walletsWithInfo = [WalletWithInfo]()
    private var initialAction: InitialAction = .none
    var shouldShowManageBackup: Bool { true }
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var title: String { String.Constants.settingsWallets.localized() }
    var canAddWallet: Bool { true }
    var analyticsName: Analytics.ViewName { .walletsList }

    init(view: WalletsListViewProtocol,
         dataAggregatorService: DataAggregatorServiceProtocol,
         initialAction: InitialAction,
         networkReachabilityService: NetworkReachabilityServiceProtocol?,
         udWalletsService: UDWalletsServiceProtocol) {
        self.view = view
        self.dataAggregatorService = dataAggregatorService
        self.initialAction = initialAction
        self.networkReachabilityService = networkReachabilityService
        self.udWalletsService = udWalletsService
        networkReachabilityService?.addListener(self)
    }
    
    func didSelectWallet(_ wallet: UDWallet, walletInfo: WalletDisplayInfo) async {
        await showDetailsOf(wallet: wallet, walletInfo: walletInfo)
    }
    
    func visibleItem(from walletInfo: WalletDisplayInfo) -> WalletsListViewController.Item {
        WalletsListViewController.Item.walletInfo(walletInfo)
    }
}

// MARK: - NewWalletsListViewPresenterProtocol
extension WalletsListViewPresenter: WalletsListViewPresenterProtocol {
    func viewDidLoad() {
        dataAggregatorService.addListener(self)
        refreshWallets()
    }
    
    func viewWillAppear() {
        Task {
            try? await Task.sleep(seconds: 0.3)
            switch initialAction {
            case .none:
                return
            case .showImportWalletOptionsPullUp:
                showAddWalletPullUp(isImportOnly: true)
            case .importWallet:
                await importNewWallet()
            case .connectWallet:
                await connectNewWallet()
            }
            initialAction = .none
        }
    }
    
    func didPressAddButton() {
        showAddWalletPullUp(isImportOnly: false)
    }
    
    func didSelectItem(_ item: WalletsListViewController.Item) {
        UDVibration.buttonTap.vibrate()
        Task {
            switch item {
            case .walletInfo(let walletInfo), .selectableWalletInfo(let walletInfo, _):
                guard let wallet = walletsWithInfo.first(where: { $0.wallet.address == walletInfo.address }) else { return }
                
                logButtonPressedAnalyticEvents(button: .walletInList)
                await didSelectWallet(wallet.wallet, walletInfo: walletInfo)
            case .manageICloudBackups:
                logButtonPressedAnalyticEvents(button: .manageICloudBackups)
                await showManageBackupsAction()
            }
        }
    }
}

// MARK: - DataResolutionServiceListener
extension WalletsListViewPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        if case .success(let resultType) = result {
            switch resultType {
            case .walletsListUpdated(let wallets):
                if self.walletsWithInfo.isEmpty,
                   wallets.isEmpty {
                    return
                }
                walletsWithInfo = wallets
                removeWalletsDuplicates()
                Task { await showWallets() }
            case .domainsUpdated, .primaryDomainChanged, .domainsPFPUpdated:
                return
            }
        }
    }
}

// MARK: - NetworkReachabilityServiceListener
extension WalletsListViewPresenter: NetworkReachabilityServiceListener {
    func networkStatusChanged(_ status: NetworkReachabilityService.Status) {
        Task { await showWallets() }
    }
}

// MARK: - Actions
private extension WalletsListViewPresenter {
    func showAddWalletPullUp(isImportOnly: Bool) {
        guard let view = self.view else { return }
        
        Task {
            let actions: [WalletDetailsAddWalletAction]
            if isImportOnly {
                actions = [.recoveryOrKey, .connect]
            } else {
                actions = WalletDetailsAddWalletAction.allCases
            }
            do {
                let action = try await appContext.pullUpViewService.showAddWalletSelectionPullUp(in: view,
                                                                                             actions: actions)
                didSelectAddWalletAction(action)
            } catch { }
        }
    }
    
    func showManageBackupsAction() async {
        guard let view = self.view else { return }
        
        guard iCloudWalletStorage.isICloudAvailable() else {
            await view.showICloudDisabledAlert()
            return
        }
        
        do {
            let action = try await appContext.pullUpViewService.showManageBackupsSelectionPullUp(in: view)
            
            switch action {
            case .restore:
                let backups = udWalletsService.fetchCloudWalletClusters().sorted(by: {
                    if $0.isCurrent || $1.isCurrent {
                        return $0.isCurrent
                    }
                    return $0.date > $1.date
                })
                
                if backups.count == 1 {
                    await view.dismissPullUpMenu()
                    await restoreWalletFrom(backup: backups[0])
                } else {
                    let displayBackups = backups.map({ ICloudBackupDisplayInfo(date: $0.date, backedUpWallets: $0.wallets, isCurrent: $0.isCurrent) })
                    let selectedBackup = try await appContext.pullUpViewService.showRestoreFromICloudBackupSelectionPullUp(in: view, backups: displayBackups)
                    if let index = displayBackups.firstIndex(where: { $0 == selectedBackup }) {
                        await view.dismissPullUpMenu()
                        await restoreWalletFrom(backup: backups[index])
                    }
                }
            case .delete:
                try await appContext.pullUpViewService.showDeleteAllICloudBackupsPullUp(in: view)
                await view.dismissPullUpMenu()
                try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                udWalletsService.eraseAllBackupClusters()
                SecureHashStorage.clearPassword()
            }
        } catch { }
    }
    
    @MainActor
    func restoreWalletFrom(backup: UDWalletsService.WalletCluster) {
        guard let view = self.view else { return }
        
        UDRouter().showRestoreWalletsFromBackupScreen(for: backup,
                                                      walletsRestoredCallback: { [weak self] in
            self?.showICloudBackupRestoredToast()
            self?.refreshWallets()
            AppReviewService.shared.appReviewEventDidOccurs(event: .didRestoreWalletsFromBackUp)
        }, in: view)
    }
    
    func showICloudBackupRestoredToast() {
        Task {
            await MainActor.run {
                appContext.toastMessageService.showToast(.iCloudBackupRestored, isSticky: false)
            }
        }
    }
    
    @MainActor
    func showDetailsOf(wallet: UDWallet, walletInfo: WalletDisplayInfo) {
        guard let nav = view?.cNavigationController else { return }
        
        UDRouter().showWalletDetailsOf(wallet: wallet,
                                       walletInfo: walletInfo,
                                       source: .walletsList,
                                       in: nav)
    }
    
    func didSelectAddWalletAction(_ action: WalletDetailsAddWalletAction) {
        Task {
            await view?.dismissPullUpMenu()
            await MainActor.run {
                switch action {
                case .create:
                    createNewWallet()
                case .recoveryOrKey:
                    importNewWallet()
                case .connect:
                    connectNewWallet()
                }
            }
        }
    }
    
    @MainActor
    func createNewWallet() {
        guard let view = self.view else { return }
        
        UDRouter().showCreateLocalWalletScreen(createdCallback: handleWalletAddedResult, in: view)
    }
    
    @MainActor
    func importNewWallet() {
        guard let view = self.view else { return }
        
        UDRouter().showImportVerifiedWalletScreen(walletImportedCallback: handleWalletAddedResult, in: view)
    }
    
    @MainActor
    func connectNewWallet() {
        guard let view = self.view else { return }
        
        UDRouter().showConnectExternalWalletScreen(walletConnectedCallback: handleWalletAddedResult, in: view)
    }
    
    func handleWalletAddedResult(_ result: AddWalletNavigationController.Result) {
        Task {
            switch result {
            case .cancelled:
                return
            case .created(let wallet), .createdAndBackedUp(let wallet):
                var walletName = String.Constants.vault.localized()
                if let displayInfo = WalletDisplayInfo(wallet: wallet, domainsCount: 0) {
                    walletName = displayInfo.walletSourceName
                }
                await appContext.toastMessageService.showToast(.walletAdded(walletName: walletName), isSticky: false)
                await fetchWallets()
                await showWallets()
                if case .createdAndBackedUp(let wallet) = result,
                   let walletInfo = walletsWithInfo.first(where: { $0.wallet.address == wallet.address })?.displayInfo {
                    await showDetailsOf(wallet: wallet, walletInfo: walletInfo)
                }
                AppReviewService.shared.appReviewEventDidOccurs(event: .walletAdded)
            }
        }
    }
}

// MARK: - Private functions
private extension WalletsListViewPresenter {
    func refreshWallets() {
        Task {
            await fetchWallets()
            await showWallets()
        }
    }
    
    func fetchWallets() async {
        walletsWithInfo = await dataAggregatorService.getWalletsWithInfo()
        removeWalletsDuplicates()
    }
    
    func showWallets() async {
        guard !walletsWithInfo.isEmpty else { return }
        
        var snapshot = WalletsListSnapshot()
        
        // Break wallets into groups
        var managedWallets = [WalletWithInfo]()
        var connectedWallets = [WalletWithInfo]()
        
        for wallet in walletsWithInfo {
            if wallet.wallet.walletState == .externalLinked {
                connectedWallets.append(wallet)
            } else {
                managedWallets.append(wallet)
            }
        }
        
        if !managedWallets.isEmpty {
            snapshot.appendSections([.managed(numberOfItems: managedWallets.count)])
            
            let items = managedWallets
                .compactMap({ $0.displayInfo })
                .managedWalletsSorted()
                .map { visibleItem(from: $0) }
            
            snapshot.appendItems(items)
        }
        
        if shouldShowManageBackup,
           networkReachabilityService?.isReachable == true {
            let backups = udWalletsService.fetchCloudWalletClusters()
            
            if !backups.isEmpty {
                if managedWallets.isEmpty {
                    snapshot.appendSections([.manageICloudExtraHeight])
                } else {
                    snapshot.appendSections([.manageICLoud])
                }
                snapshot.appendItems([.manageICloudBackups])
            }
        }
        
        if !connectedWallets.isEmpty {
            let items = connectedWallets
                .compactMap({ $0.displayInfo })
                .map { visibleItem(from: $0) }
            
            snapshot.appendSections([.connected(numberOfItems: items.count)])
            snapshot.appendItems(items)
        }
        
        await view?.applySnapshot(snapshot, animated: false)
    }
    
    func removeWalletsDuplicates() {
        var allWalletsWithInfo = self.walletsWithInfo
        
        // Check for duplicates
        var walletsWithInfo = [WalletWithInfo]()
        for walletWithInfo in allWalletsWithInfo {
            if let displayInfo = walletWithInfo.displayInfo,
               walletsWithInfo.first(where: { $0.displayInfo == displayInfo }) == nil {
                walletsWithInfo.append(walletWithInfo)
            }
        }
        self.walletsWithInfo = walletsWithInfo
    }
}

// MARK: - WalletsListViewPresenter
extension WalletsListViewPresenter {
    enum InitialAction {
        case none, showImportWalletOptionsPullUp, importWallet, connectWallet
    }
}
