//
//  ConnectExternalWalletViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.09.2022.
//

import Foundation

protocol ConnectExternalWalletViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var analyticsName: Analytics.ViewName { get }
    
    func didSelectItem(_ item: ConnectExternalWalletViewController.Item)
    func applicationWillEnterForeground()
}

class ConnectExternalWalletViewPresenter: WalletConnector {
    
    private(set) weak var view: ConnectExternalWalletViewProtocol?
    private let udWalletsService: UDWalletsServiceProtocol
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var analyticsName: Analytics.ViewName { .unspecified }
    private var connectingWalletName: String?

    init(view: ConnectExternalWalletViewProtocol,
         udWalletsService: UDWalletsServiceProtocol,
         walletConnectClientService: WalletConnectClientServiceProtocol) {
        self.view = view
        self.udWalletsService = udWalletsService
        walletConnectClientService.delegate = self
      
    }
    func updateUI() {}
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

        switch item {
        case .externalWallet(let description):
            let wcWalletSelected = description.walletRecord
            logButtonPressedAnalyticEvents(button: .externalWalletSelected, parameters: [.externalWallet: wcWalletSelected.name])

            if description.isInstalled {
                connectingWalletName = wcWalletSelected.name
                self.evokeConnectExternalWallet(wcWallet: wcWalletSelected)
            } else if let appStoreId = wcWalletSelected.make?.appStoreId {
                view?.openAppStore(for: appStoreId)
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
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
}

// MARK: - WalletConnectDelegate
extension ConnectExternalWalletViewPresenter: WalletConnectDelegate {
    func failedToConnect() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.view?.showSimpleAlert(title: String.Constants.connectionFailed.localized(),
                                       body: String.Constants.failedToConnectExternalWallet.localized())
            appContext.analyticsService.log(event: .failedToConnectExternalWallet, withParameters: [.externalWallet: self.connectingWalletName ?? "Unknown",
                                                                                                .viewName: self.analyticsName.rawValue])
            self.connectingWalletName = nil
        }
    }
    
    func didConnect(to walletAddress: HexAddress?, with wcRegistryWallet: WCRegistryWalletProxy?) {
        appContext.analyticsService.log(event: .didConnectToExternalWallet, withParameters: [.externalWallet: connectingWalletName ?? "Unknown",
                                                                                         .viewName: analyticsName.rawValue])
        connectingWalletName = nil
        guard let walletAddress = walletAddress else {
            Debugger.printFailure("WC wallet connected with errors, walletAddress is nil", critical: true)
            return
        }
        
        guard let proxy = wcRegistryWallet, let wcWallet = WCWalletsProvider.findBy(walletProxy: proxy)  else {
            Debugger.printFailure("Failed to find an installed wallet that connected", critical: true)
            return
        }
        
        do {
            let wallet = try udWalletsService.addExternalWalletWith(address: walletAddress,
                                                                    walletRecord: wcWallet)
            
            didConnectWallet(wallet: wallet)
        } catch WalletError.ethWalletAlreadyExists {
            Debugger.printWarning("Attempt to connect a wallet already connected")
            DispatchQueue.main.async { [weak self] in
                self?.view?.showSimpleAlert(title: String.Constants.connectionFailed.localized(),
                                            body: String.Constants.walletAlreadyConnectedError.localized())
            }
        } catch { }
    }
    
    func didDisconnect(from accounts: [HexAddress]?, with wcRegistryWallet: WCRegistryWalletProxy?) {
        // no op
    }
}

extension ConnectExternalWalletViewPresenter {
    struct ExternalWalletDescription {
        let walletRecord: WCWalletsProvider.WalletRecord
        let isInstalled: Bool
    }
}
