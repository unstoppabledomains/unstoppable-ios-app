//
//  HomeWalletLinkNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.02.2024.
//

import SwiftUI

struct HomeWalletLinkNavigationDestination {
    
    @ViewBuilder
    static func viewFor(navigationDestination: HomeWalletNavigationDestination) -> some View {
        switch navigationDestination {
        case .settings:
            SettingsViewControllerWrapper()
                .toolbar(.hidden, for: .navigationBar)
        case .qrScanner(let selectedWallet):
            QRScannerViewControllerWrapper(selectedWallet: selectedWallet, qrRecognizedCallback: { })
                .navigationTitle(String.Constants.scanQRCodeTitle.localized())
                .navigationBarTitleDisplayMode(.inline)
        case .minting(let mode, let mintedDomains, let domainsMintedCallback, let mintingNavProvider):
            MintDomainsNavigationControllerWrapper(mode: mode,
                                                   mintedDomains: mintedDomains,
                                                   domainsMintedCallback: domainsMintedCallback,
                                                   mintingNavProvider: mintingNavProvider)
            .toolbar(.hidden, for: .navigationBar)
        case .purchaseDomains(let callback):
            PurchaseDomainsNavigationControllerWrapper(domainsPurchasedCallback: callback)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
    
}
