//
//  PurchaseDomains.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2024.
//

import Foundation

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
}
