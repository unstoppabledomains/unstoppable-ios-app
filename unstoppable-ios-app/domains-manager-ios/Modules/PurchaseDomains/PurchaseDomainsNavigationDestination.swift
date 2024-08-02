//
//  PurchaseDomainsNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2024.
//

import SwiftUI

extension PurchaseDomains {
    enum NavigationDestination: Hashable {
        case fillProfileForDomain(_ domain: DomainToPurchase)
        case checkout(CheckoutData)
        case purchased(PurchaseDomainsViewModel)
        
        var isWithCustomTitle: Bool {
            true
        }
    }
    
    struct LinkNavigationDestination {
        
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .fillProfileForDomain(let domain):
                SendCryptoQRWalletAddressScannerView()
            case .checkout(let checkoutData):
                PurchaseDomainsCheckoutView(domain: checkoutData.domains[0],
                                            selectedWallet: checkoutData.selectedWallet,
                                            wallets: checkoutData.wallets,
                                            profileChanges: checkoutData.profileChanges ?? .init(domainName: checkoutData.domains[0].name))
            case .purchased(let viewModel):
                PurchaseDomainsHappyEndViewControllerWrapper(viewModel: viewModel)
            }
        }
        
    }
}
