//
//  WalletDetailsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.05.2022.
//

import UIKit
import Combine

@MainActor
protocol WalletDetailsViewPresenterProtocol: BasePresenterProtocol {
    var walletAddress: String { get }
    func didSelectItem(_ item: WalletDetailsViewController.Item)
}

@MainActor
final class WalletDetailsViewPresenter: ViewAnalyticsLogger {
    
    private weak var view: WalletDetailsViewProtocol?
    private var wallet: WalletEntity
    private let networkReachabilityService: NetworkReachabilityServiceProtocol?
    private let udWalletsService: UDWalletsServiceProtocol
    private let walletConnectServiceV2: WalletConnectServiceV2Protocol
    private var cancellables: Set<AnyCancellable> = []

    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }
    var walletRemovedCallback: EmptyCallback?
    
    init(view: WalletDetailsViewProtocol,
         wallet: WalletEntity,
         networkReachabilityService: NetworkReachabilityServiceProtocol?,
         udWalletsService: UDWalletsServiceProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol) {
        self.view = view
        self.wallet = wallet
        self.networkReachabilityService = networkReachabilityService
        self.udWalletsService = udWalletsService
        self.walletConnectServiceV2 = walletConnectServiceV2
        appContext.walletsDataService.walletsPublisher.receive(on: DispatchQueue.main).sink { [weak self] wallets in
            self?.walletsUpdated(wallets)
        }.store(in: &cancellables)
    }
}

// MARK: - WalletDetailsViewPresenterProtocol
extension WalletDetailsViewPresenter: WalletDetailsViewPresenterProtocol {
    var walletAddress: String { wallet.address }
    
    func viewDidLoad() {
        networkReachabilityService?.addListener(self)
        showWalletDetails()
    }
    
    func viewDidAppear() {
        updateTitle()
    }
    
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
                    showWalletDomains()
                case .reverseResolution(let state):
                    switch state {
                    case .notSet:
                        let result = await UDRouter().runSetupReverseResolutionFlow(in: view,
                                                                                    for: wallet,
                                                                                    mode: .chooseFirstDomain)
                        handleSetupReverseResolution(result: result)
                    case .setFor(let domain, _, _):
                        let result = await UDRouter().runSetupReverseResolutionFlow(in: view,
                                                                                    for: wallet,
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

// MARK: - NetworkReachabilityServiceListener
extension WalletDetailsViewPresenter: NetworkReachabilityServiceListener {
    func networkStatusChanged(_ status: NetworkReachabilityStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.showWalletDetails()
        }
    }
}

// MARK: - Private functions
private extension WalletDetailsViewPresenter {
    func walletsUpdated(_ wallets: [WalletEntity]) {
        if let wallet = wallets.findWithAddress(wallet.address) {
            self.wallet = wallet
            showWalletDetails()
        } else {
            Task { await MainActor.run { view?.cNavigationController?.popViewController(animated: true) } }
        }
    }
    func showWalletDetails() {
        Task {
            var snapshot = WalletDetailsSnapshot()
            let isReverseResolutionChangeAllowed = wallet.isReverseResolutionChangeAllowed()
            
            let walletInfo = wallet.displayInfo
            let walletDomains = wallet.domains
            let domainsAvailableForRR = walletDomains.availableForRRItems()
            let rrDomain = wallet.rrDomain
            
            let isUpdatingRecords = wallet.domains.first(where: { $0.isUpdatingRecords }) == nil
            let isRRSetupInProgress = wallet.rrDomain?.state == .updatingReverseResolution
            
            let isExternalWallet: Bool
            switch walletInfo.source {
                // TODO: - MPC
            case .locallyGenerated, .imported, .mpc:
                isExternalWallet = false
            case .external:
                isExternalWallet = true
            }
            
            // Top info
            snapshot.appendSections([.topInfo])
            snapshot.appendItems([.topInfo(.init(walletInfo: walletInfo,
                                                 domain: rrDomain,
                                                 isUpdating: isUpdatingRecords,
                                                 copyButtonPressed: { [weak self] in self?.copyAddressButtonPressed() },
                                                 externalBadgePressed: { [weak self] in self?.externalBadgePressed() }))])
            let isNetworkReachable = networkReachabilityService?.isReachable == true
            
            // Backup and recovery phrase
            if !isExternalWallet {
                snapshot.appendSections([.backUpAndRecovery])
                snapshot.appendItems([.listItem(.backUp(state: walletInfo.backupState,
                                                        isOnline: isNetworkReachable))])
                if let recoveryType = UDWallet.RecoveryType(walletType: wallet.udWallet.walletType) {
                    snapshot.appendItems([.listItem(.recoveryPhrase(recoveryType: recoveryType))])
                }
            }
            
            // Rename, Reverse Resolution and domains
            snapshot.appendSections([.renameAndDomains])
            snapshot.appendItems([.listItem(.rename)])
            
            if let rrDomain {
                if isRRSetupInProgress {
                    snapshot.appendItems([.listItem(.reverseResolution(state: .settingFor(domain: rrDomain)))])
                } else {
                    if domainsAvailableForRR.count == 1 {
                        // For single domain there's no reason to show updating records state since user can't change it. 
                        snapshot.appendItems([.listItem(.reverseResolution(state: .setFor(domain: rrDomain, isEnabled: false, isUpdatingRecords: false)))])
                    } else {
                        snapshot.appendItems([.listItem(.reverseResolution(state: .setFor(domain: rrDomain,
                                                                                          isEnabled: isReverseResolutionChangeAllowed,
                                                                                          isUpdatingRecords: !isReverseResolutionChangeAllowed)))])
                    }
                }
            } else {
                if !domainsAvailableForRR.isEmpty {
                    snapshot.appendItems([.listItem(.reverseResolution(state: .notSet(isEnabled: isReverseResolutionChangeAllowed)))])
                }
            }
            
            if !walletDomains.isEmpty {
                snapshot.appendItems([.listItem(.domains(domainsCount: walletDomains.count,
                                                         walletName: walletInfo.walletSourceName))])
            }
            
            // Remove wallet
            snapshot.appendSections([.removeWallet])
            if isExternalWallet {
                snapshot.appendItems([.listItem(.importWallet)])
            }
            snapshot.appendItems([.listItem(.removeWallet(isConnected: walletInfo.isConnected,
                                                          walletName: walletInfo.walletSourceName))])
            
            view?.applySnapshot(snapshot, animated: true)
        }
    }
    
    func revealRecoveryPhrase(recoveryType: UDWallet.RecoveryType) {
        guard let view = self.view else { return }
        
        let wallet = self.wallet
        Task {
            do {
                try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                UDRouter().showRecoveryPhrase(of: wallet.udWallet,
                                              recoveryType: recoveryType,
                                              in: view,
                                              dismissCallback: {
                    AppReviewService.shared.appReviewEventDidOccurs(event: .didRevealPK)
                })
            }
        }
    }
    
    func askToRemoveWallet() {
        guard let view = self.view else { return }
        Task {
            do {
                try await appContext.pullUpViewService.showRemoveWalletPullUp(in: view, walletInfo: wallet.displayInfo)
                await view.dismissPullUpMenu()
                try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                await removeWallet()
                walletRemovedCallback?()
            }
        }
    }
    
    func indicateWalletRemoved() {
        if wallet.udWallet.walletType == .externalLinked {
            appContext.toastMessageService.showToast(.walletDisconnected, isSticky: false)
        } else {
            appContext.toastMessageService.showToast(.walletRemoved(walletName: wallet.displayInfo.walletSourceName), isSticky: false)
        }
    }
    
    func removeWallet() async {
        udWalletsService.remove(wallet: wallet.udWallet)
        // WC2 only
        await walletConnectServiceV2.disconnect(from: wallet.address)
        let wallets = udWalletsService.getUserWallets()
        guard !wallets.isEmpty else { return }
        indicateWalletRemoved()
    }
    
    func copyAddressButtonPressed() {
        logButtonPressedAnalyticEvents(button: .copyWalletAddress)
        CopyWalletAddressPullUpHandler.copyToClipboard(address: wallet.address, ticker: BlockchainType.Ethereum.rawValue)
    }
 
    func externalBadgePressed() {
        guard let view = self.view else { return }

        logButtonPressedAnalyticEvents(button: .showConnectedWalletInfo)
        appContext.pullUpViewService.showConnectedWalletInfoPullUp(in: view)
    }
    
    func showRenameWalletScreen() {
        guard let view = self.view else { return }

        UDRouter().showRenameWalletScreen(of: wallet.udWallet,
                                          walletDisplayInfo: wallet.displayInfo,
                                          nameUpdatedCallback: { _ in },
                                          in: view)
    }
    
    func showBackupWalletScreenIfAvailable() {
        guard let view = self.view else { return }

        guard iCloudWalletStorage.isICloudAvailable() else {
            view.showICloudDisabledAlert()
            return
        }
        
        UDRouter().showBackupWalletScreen(for: wallet.udWallet, walletBackedUpCallback: { [weak self] updatedWallet in
            self?.updateTitle()
            AppReviewService.shared.appReviewEventDidOccurs(event: .walletBackedUp)
        }, in: view)
    }
    
    func showWalletDomains() {
        guard let view = self.view else { return }
        
        UDRouter().showWalletDomains(wallet: wallet,
                                     in: view)
    }
    
    func updateTitle() {
        view?.set(title: wallet.displayName)
    }
    
    func handleSetupReverseResolution(result: SetupWalletsReverseResolutionNavigationManager.Result) {
        switch result {
        case .cancelled, .failed:
            return
        case .set:
            showWalletDetails()
        }
    }
    
    func importExternalWallet() {
        guard let view = self.view else { return }
        
        UDRouter().showImportExistingExternalWalletModule(in: view,
                                                          externalWalletInfo: wallet.displayInfo) { [weak self] _ in
            self?.view?.presentedViewController?.dismiss(animated: true)
        }
    }
    
    func showReverseResolutionInProgress(for domainDisplayInfo: DomainDisplayInfo) {
        Task {
            guard let view = self.view else { return }

            do {
                let domain = domainDisplayInfo.toDomainItem()
                UDRouter().showReverseResolutionInProgressScreen(in: view,
                                                                 domain: domain,
                                                                 domainDisplayInfo: domainDisplayInfo,
                                                                 walletInfo: wallet.displayInfo)
            }
        }
    }
}
