//
//  PurchaseDomainsNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2024.
//

import SwiftUI

extension PurchaseDomains {
    enum NavigationDestination: Hashable {
        case root(HomeTabRouter)
        case checkout(_ checkoutData: CheckoutData, viewModel: PurchaseDomainsViewModel)
        case purchased(_ purchasedDomainsData: PurchasedDomainsData, viewModel: PurchaseDomainsViewModel)
        
        var isWithCustomTitle: Bool {
            if case .purchased = self {
                return false
            }
            return true
        }
        
        var progress: Double {
            switch self {
            case .root:
                return 1 / 6
            case .checkout:
                return 5 / 6
            case .purchased:
                return 1
            }
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.root, .root):
                return true
            case (.checkout, .checkout):
                return true
            case (.purchased, .purchased):
                return true
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .root:
                hasher.combine("root")
            case .checkout:
                hasher.combine("checkout")
            case .purchased:
                hasher.combine("purchased")
            }
        }
    }
    
    struct LinkNavigationDestination {
        
        @MainActor
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .root(let router):
                PurchaseDomainsRootView(viewModel: PurchaseDomainsViewModel(router: router))
            case .checkout(let checkoutData, let viewModel):
                PurchaseDomainsCheckoutView(domains: checkoutData.domains,
                                            selectedWallet: checkoutData.selectedWallet,
                                            wallets: checkoutData.wallets,
                                            profileChanges: checkoutData.profileChanges ?? .init(domainName: checkoutData.domains[0].name))
                .environmentObject(viewModel)
            case .purchased(let purchasedDomainsData, let viewModel):
                PurchaseDomainsCompletedView(purchasedDomainsData: purchasedDomainsData)
                    .environmentObject(viewModel)
            }
        }
        
    }
}
