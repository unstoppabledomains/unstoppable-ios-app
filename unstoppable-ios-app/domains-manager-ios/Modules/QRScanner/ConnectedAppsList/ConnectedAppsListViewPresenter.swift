//
//  ConnectedAppsListViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2022.
//

import Foundation

@MainActor
protocol ConnectedAppsListViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: ConnectedAppsListViewController.Item)
}

@MainActor
final class ConnectedAppsListViewPresenter: ViewAnalyticsLogger {
    
    private weak var view: ConnectedAppsListViewProtocol?
    private let walletConnectServiceV2: WalletConnectServiceV2Protocol
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }
    var scanCallback: EmptyCallback?
    
    init(view: ConnectedAppsListViewProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol) {
        self.view = view
        self.walletConnectServiceV2 = walletConnectServiceV2
    }
}

// MARK: - ConnectedAppsListViewPresenterProtocol
extension ConnectedAppsListViewPresenter: ConnectedAppsListViewPresenterProtocol {
    func viewDidLoad() {
        showConnectedAppsList()
        appContext.wcRequestsHandlingService.addListener(self)
    }
    
    func didSelectItem(_ item: ConnectedAppsListViewController.Item) { }
}

// MARK: - WalletConnectServiceListener
extension ConnectedAppsListViewPresenter: WalletConnectServiceConnectionListener {
    nonisolated
    func didConnect(to app: UnifiedConnectAppInfo) {
        Task {
            await showConnectedAppsList()
        }
    }
    
    nonisolated
    func didDisconnect(from app: UnifiedConnectAppInfo) {
        Task {
            await showConnectedAppsList()
        }
    }
}

// MARK: - Private functions
private extension ConnectedAppsListViewPresenter {
    func showConnectedAppsList() {
        let connectedAppsUnified: [any UnifiedConnectAppInfoProtocol] = walletConnectServiceV2.getConnectedApps()
        
        var snapshot = ConnectedAppsListSnapshot()
        guard !connectedAppsUnified.isEmpty else {
            snapshot.appendSections([.emptyState])
            snapshot.appendItems([.emptyState(scanCallback: { [weak self] in 
                self?.scanCallback?()
            })])
            view?.applySnapshot(snapshot, animated: true)
            return
        }
        
        let wallets = appContext.walletsDataService.wallets
        let walletsDisplayInfo = wallets.map({ $0.displayInfo })
        let domains = wallets.combinedDomains()
        
        // Fill snapshot
        let appsGroupedByWallet = [String : [any UnifiedConnectAppInfoProtocol]].init(grouping: connectedAppsUnified,
                                                                              by: { $0.walletAddress })
        
        for displayInfo in walletsDisplayInfo {
            if let apps = appsGroupedByWallet[displayInfo.address] {
                guard let displayInfo = walletsDisplayInfo.first(where: { $0.address == apps[0].walletAddress }) else { continue }
                
                var items: [ConnectedAppsListViewController.Item] = apps.map({ app in
                    let domainItem = app.domain
                    let domainDisplayInfo: DomainDisplayInfo
                    if let _domain = domains.first(where: { $0.isSameEntity(domainItem) }) {
                        domainDisplayInfo = _domain
                    } else {
                        Debugger.printFailure("Forced to display a domain that has been disconnected, \(app.domain.name)", critical: true)
                        domainDisplayInfo = DomainDisplayInfo(domainItem: domainItem,
                                                   pfpInfo: nil,
                                                   isSetForRR: false)
                    }
                    
                    var blockchainTypesArray: [BlockchainType] = app.chainIds.compactMap({ (try? UnsConfigManager.getBlockchainType(from: $0)) })
                    if blockchainTypesArray.isEmpty {
                        blockchainTypesArray.append(.Ethereum) /// Fallback to V1 when chainId could be nil and we set ETH as default
                    }
                    
                    let blockchainTypes = NonEmptyArray(items: blockchainTypesArray)! // safe after the previous lines
                    
                    let supportedNetworks = BlockchainType.supportedCases.map({ $0.fullName })
                    let displayInfo = ConnectedAppsListViewController.AppItemDisplayInfo(app: app,
                                                                                         domain: domainDisplayInfo,
                                                                                         blockchainTypes: blockchainTypes,
                                                                                         actions: [.domainInfo(domain: domainDisplayInfo),
                                                                                                   .networksInfo(networks: supportedNetworks),
                                                                                                   .disconnect])
                    return ConnectedAppsListViewController.Item.app(displayInfo, actionCallback: { [weak self] action in
                        self?.handleAction(action, for: app)
                    })
                })
                items = Set(items).sorted(by: { $0.appName < $1.appName })
                
                if items.isEmpty {
                    continue
                }
                snapshot.appendSections([.walletApps(walletName: displayInfo.displayName)])
                snapshot.appendItems(items)
            }
        }
        
        view?.applySnapshot(snapshot, animated: true)
    }
    
    func handleAction(_ action: ConnectedAppsListViewController.ItemAction,
                      for app: any UnifiedConnectAppInfoProtocol) {
        logButtonPressedAnalyticEvents(button: action.analyticName, parameters: [.wcAppName: app.appName])
        UDVibration.buttonTap.vibrate()
        Task {
            guard let view = self.view else { return }
            switch action {
            case .domainInfo(let domain):
                await appContext.pullUpViewService.showConnectedAppDomainInfoPullUp(for: domain,
                                                                                    connectedApp: app,
                                                                                    in: view)
            case .networksInfo:
                appContext.pullUpViewService.showConnectedAppNetworksInfoPullUp(in: view)
            case .disconnect:
                try await walletConnectServiceV2.disconnect(app: app)
            }
        }
    }
}
