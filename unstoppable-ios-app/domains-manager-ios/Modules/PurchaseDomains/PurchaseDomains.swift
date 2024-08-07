//
//  PurchaseDomains.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2024.
//

import SwiftUI

enum PurchaseDomains { } // Namespace

extension PurchaseDomains {
    enum FlowAction {
        case didSelectDomains(_ domains: [DomainToPurchase])
        case didFillProfileForDomain(_ domain: DomainToPurchase, profileChanges: DomainProfilePendingChanges)
        case didPurchaseDomains
        case goToDomains
    }
}

extension PurchaseDomains {
    struct CheckoutData: Hashable {
        let domains: [DomainToPurchase]
        let profileChanges: DomainProfilePendingChanges?
        let selectedWallet: WalletEntity
        let wallets: [WalletEntity]
    }
    
    enum EmptyStateMode {
        case start
        case noResults
        case error
        
        var title: String {
            switch self {
            case .start:
                return "Start typing"
            case .noResults:
                return String.Constants.noAvailableDomains.localized()
            case .error:
                return String.Constants.somethingWentWrong.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .start:
                return nil
            case .noResults:
                return String.Constants.tryEnterDifferentName.localized()
            case .error:
                return String.Constants.pleaseCheckInternetConnection.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .start:
                return .searchIcon
            case .noResults, .error:
                return .grimaseIcon
            }
        }
    }
}

extension PurchaseDomains {
    final class LocalCart: ObservableObject {
        @Published
        private(set) var domains: [DomainToPurchase] = []
        @Published var isShowingCart = false

        var totalPrice: Int { domains.reduce(0, { $0 + $1.price })}
        
        func isDomainInCart(_ domain: DomainToPurchase) -> Bool {
            domains.firstIndex(where: { $0.name == domain.name }) != nil
        }
        
        func addDomain(_ domain: DomainToPurchase) {
            guard !isDomainInCart(domain) else { return }
            
            domains.append(domain)
        }
        
        func removeDomain(_ domain: DomainToPurchase) {
            if let i = domains.firstIndex(where: { $0.name == domain.name }) {
                domains.remove(at: i)
            }
        }
        
        func clearCart() {
            domains.removeAll()
        }
    }
}
