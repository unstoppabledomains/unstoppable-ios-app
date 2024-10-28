//
//  HomeWalletNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.01.2024.
//

import SwiftUI

enum HomeWalletNavigationDestination: Hashable {
    case settings(SettingsView.InitialAction)
    case qrScanner(selectedWallet: WalletEntity)
    case minting(mode: MintDomainsNavigationController.Mode,
                 mintedDomains: [DomainDisplayInfo],
                 domainsMintedCallback: MintDomainsNavigationController.DomainsMintedCallback,
                 mintingNavProvider: (MintDomainsNavigationController)->())
    case purchaseDomains(PurchaseDomains.NavigationDestination)
    case login(mode: LoginFlowNavigationController.Mode, callback: LoginFlowNavigationController.LoggedInCallback)
    case walletDetails(WalletEntity)
    case securitySettings
    case setupPasscode(SetupPasscodeViewController.Mode)
    case mpcSetup2FAEnable(wallet: WalletEntity,
                           mpcMetadata: MPCWalletMetadata)

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
        case (.login, .login):
            return true
        case (.walletDetails, .walletDetails):
            return true
        case (.securitySettings, .securitySettings):
            return true
        case (.setupPasscode, .setupPasscode):
            return true
        case (.mpcSetup2FAEnable(let lhsWallet, _), .mpcSetup2FAEnable(let rhsWallet, _)):
            return lhsWallet.address == rhsWallet.address
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
        case .login:
            hasher.combine("login")
        case .walletDetails:
            hasher.combine("walletDetails")
        case .securitySettings:
            hasher.combine("securitySettings")
        case .setupPasscode:
            hasher.combine("setupPasscode")
        case .mpcSetup2FAEnable(let wallet, _):
            hasher.combine("mpcSetup2FAEnable_\(wallet.address)")
        }
    }
    
}

struct HomeWalletLinkNavigationDestination {
    
    @MainActor
    @ViewBuilder
    static func viewFor(navigationDestination: HomeWalletNavigationDestination) -> some View {
        switch navigationDestination {
        case .settings(let initialAction):
            SettingsView(initialAction: initialAction)
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
        case .purchaseDomains(let destination):
            PurchaseDomains.LinkNavigationDestination.viewFor(navigationDestination: destination)
        case .login(let mode, let callback):
            LoginFlowNavigationControllerWrapper(mode: mode,
                                                 callback: callback)
                .toolbar(.hidden, for: .navigationBar)
                .ignoresSafeArea()
        case .walletDetails(let wallet):
            WalletDetailsView(wallet: wallet, source: .settings)
        case .mpcSetup2FAEnable(let wallet,
                                let mpcMetadata):
            MPCSetup2FAEnableView(wallet: wallet, mpcMetadata: mpcMetadata)
        case .securitySettings:
            SecuritySettingsView()
        case .setupPasscode(let mode):
            SetupPasscodeViewControllerWrapper(mode: mode)
                .ignoresSafeArea()
        }
    }
    
}
