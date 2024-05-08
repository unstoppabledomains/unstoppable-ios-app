//
//  HomeWalletNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.01.2024.
//

import SwiftUI

enum HomeWalletNavigationDestination: Hashable {
    case settings
    case qrScanner(selectedWallet: WalletEntity)
    case minting(mode: MintDomainsNavigationController.Mode,
                 mintedDomains: [DomainDisplayInfo],
                 domainsMintedCallback: MintDomainsNavigationController.DomainsMintedCallback,
                 mintingNavProvider: (MintDomainsNavigationController)->())
    case purchaseDomains(domainsPurchasedCallback: PurchaseDomainsNavigationController.DomainsPurchasedCallback)
    case walletsList(WalletsListViewPresenter.InitialAction)
    case login(mode: LoginFlowNavigationController.Mode, callback: LoginFlowNavigationController.LoggedInCallback)
    case walletDetails(WalletEntity)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.settings, .settings):
            return true
        case (.qrScanner, .qrScanner):
            return true
        case (.minting, .minting):
            return true
        case (.purchaseDomains, .purchaseDomains):
            return true
        case (.walletsList, .walletsList):
            return true
        case (.login, .login):
            return true
        case (.walletDetails, .walletDetails):
            return true
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .settings:
            hasher.combine("settings")
        case .qrScanner:
            hasher.combine("qrScanner")
        case .minting:
            hasher.combine("minting")
        case .purchaseDomains:
            hasher.combine("purchaseDomains")
        case .walletsList:
            hasher.combine("walletsList")
        case .login:
            hasher.combine("login")
        case .walletDetails:
            hasher.combine("walletDetails")
        }
    }
    
}

struct HomeWalletLinkNavigationDestination {
    
    @ViewBuilder
    static func viewFor(navigationDestination: HomeWalletNavigationDestination) -> some View {
        switch navigationDestination {
        case .settings:
            SettingsView()
        case .qrScanner(let selectedWallet):
            QRScannerViewControllerWrapper(selectedWallet: selectedWallet, qrRecognizedCallback: { })
                .navigationTitle(String.Constants.scanQRCodeTitle.localized())
                .navigationBarTitleDisplayMode(.inline)
                .ignoresSafeArea()
        case .minting(let mode, let mintedDomains, let domainsMintedCallback, let mintingNavProvider):
            MintDomainsNavigationControllerWrapper(mode: mode,
                                                   mintedDomains: mintedDomains,
                                                   domainsMintedCallback: domainsMintedCallback,
                                                   mintingNavProvider: mintingNavProvider)
            .toolbar(.hidden, for: .navigationBar)
            .ignoresSafeArea()
        case .purchaseDomains(let callback):
            PurchaseDomainsNavigationControllerWrapper(domainsPurchasedCallback: callback)
                .toolbar(.hidden, for: .navigationBar)
                .ignoresSafeArea()
        case .walletsList(let initialAction):
            WalletsListViewControllerWrapper(initialAction: initialAction)
                .toolbar(.hidden, for: .navigationBar)
                .ignoresSafeArea()
        case .login(let mode, let callback):
            LoginFlowNavigationControllerWrapper(mode: mode,
                                                 callback: callback)
                .toolbar(.hidden, for: .navigationBar)
                .ignoresSafeArea()
        case .walletDetails(let wallet):
            WalletDetailsView(wallet: wallet)
        }
    }
    
}
