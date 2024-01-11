//
//  ConnectExternalWalletViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.09.2022.
//

import Foundation

@MainActor
protocol ConnectExternalWalletViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var analyticsName: Analytics.ViewName { get }
    
    func didSelectItem(_ item: ConnectExternalWalletViewController.Item)
    func applicationWillEnterForeground()
}

@MainActor
class ConnectExternalWalletViewPresenter {
    
    private(set) weak var view: ConnectExternalWalletViewProtocol?
    private let udWalletsService: UDWalletsServiceProtocol
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var analyticsName: Analytics.ViewName { .unspecified }

    init(view: ConnectExternalWalletViewProtocol,
         udWalletsService: UDWalletsServiceProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol) {
        self.view = view
        self.udWalletsService = udWalletsService
    }
    func didConnectWallet(wallet: UDWallet) {
        Vibration.success.vibrate()
    }
    func viewDidLoad() { }
    func viewWillAppear() {
        showData()
    }
}

// MARK: - ConnectExternalWalletViewPresenterProtocol
extension ConnectExternalWalletViewPresenter: ConnectExternalWalletViewPresenterProtocol {
    func didSelectItem(_ item: ConnectExternalWalletViewController.Item) {
        UDVibration.buttonTap.vibrate()
        guard let view else { return }
        
        switch item {
        case .externalWallet(let description):
            let wcWalletSelected = description.walletRecord
            logButtonPressedAnalyticEvents(button: .externalWalletSelected, parameters: [.externalWallet: wcWalletSelected.name])

            if description.isInstalled {
                Task { @MainActor in
                    let connector = ExternalWalletConnectionService()
                    do {
                        let wallet = try await connector.connect(externalWallet: wcWalletSelected)
                        didConnectWallet(wallet: wallet)
                    } catch ExternalWalletConnectionService.ConnectionError.noResponse {
                        // Ignore
                    } catch ExternalWalletConnectionService.ConnectionError.ethWalletAlreadyExists {
                        view.showSimpleAlert(title: String.Constants.error.localized(),
                                             body: String.Constants.walletAlreadyConnectedError.localized())
                    } catch ExternalWalletConnectionService.ConnectionError.walletsLimitExceeded(let limit) {
                        await appContext.pullUpViewService.showWalletsNumberLimitReachedPullUp(in: view,
                                                                                               maxNumberOfWallets: limit)
                    } catch {
                        view.showSimpleAlert(title: String.Constants.connectionFailed.localized(),
                                              body: String.Constants.failedToConnectExternalWallet.localized())
                    }
                }
            } else if let appStoreId = wcWalletSelected.make?.appStoreId {
                view.openAppStore(for: appStoreId)
            } else {
                Debugger.printFailure("No AppStore Id for external wallet \(wcWalletSelected.name)", critical: true)
            }
        case .header:
            return
        }
    }
    
    func applicationWillEnterForeground() {
        showData()
    }
}

// MARK: - Private functions
private extension ConnectExternalWalletViewPresenter {
    func showData() {
        Task {
            var snapshot = ConnectExternalWalletSnapshot()
            
            snapshot.appendSections([.header])
            snapshot.appendItems([.header])
           
            let walletRecords = WCWalletsProvider.getGroupedInstalledAndNotWcWallets(for: .supported)
            
            if walletRecords.installed.isEmpty || walletRecords.notInstalled.isEmpty {
                snapshot.appendSections([.single])
                if walletRecords.installed.isEmpty {
                    snapshot.appendItems(walletRecords.notInstalled.map({ ConnectExternalWalletViewController.Item.externalWallet(.init(walletRecord: $0,
                                                                                                                                        isInstalled: false)) }))
                } else {
                    snapshot.appendItems(walletRecords.installed.map({ ConnectExternalWalletViewController.Item.externalWallet(.init(walletRecord: $0,
                                                                                                                                        isInstalled: true)) }))
                }
            } else {
                snapshot.appendSections([.labeled(header: String.Constants.installed.localized())])
                snapshot.appendItems(walletRecords.installed.map({ ConnectExternalWalletViewController.Item.externalWallet(.init(walletRecord: $0,
                                                                                                                                 isInstalled: true)) }))
                
                snapshot.appendSections([.labeled(header: String.Constants.notInstalled.localized())])
                snapshot.appendItems(walletRecords.notInstalled.map({ ConnectExternalWalletViewController.Item.externalWallet(.init(walletRecord: $0,
                                                                                                                                 isInstalled: false)) }))
            }
            
            view?.applySnapshot(snapshot, animated: true)
        }
    }
}

extension ConnectExternalWalletViewPresenter {
    struct ExternalWalletDescription {
        let walletRecord: WCWalletsProvider.WalletRecord
        let isInstalled: Bool
    }
}
