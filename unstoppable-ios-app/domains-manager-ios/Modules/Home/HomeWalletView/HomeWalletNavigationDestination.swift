//
//  HomeWalletNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.01.2024.
//

import Foundation

enum HomeWalletNavigationDestination: Hashable {
    case settings
    case qrScanner
    case minting(mode: MintDomainsNavigationController.Mode,
                 mintedDomains: [DomainDisplayInfo],
                 domainsMintedCallback: MintDomainsNavigationController.DomainsMintedCallback)
    case purchaseDomains(domainsPurchasedCallback: PurchaseDomainsNavigationController.DomainsPurchasedCallback)
    
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
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .settings:
            hasher.combine(0)
        case .qrScanner:
            hasher.combine(1)
        case .minting:
            hasher.combine(2)
        case .purchaseDomains:
            hasher.combine(3)
        }
    }
    
    }
