//
//  PurchaseDomainsServiceProtocol.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import Foundation

protocol PurchaseDomainsServiceProtocol {
    var cartStatusPublisher: Published<PurchaseDomainCartStatus>.Publisher  { get }
    var isApplePaySupported: Bool { get }
    
    func searchForDomains(key: String) async throws -> [DomainToPurchase]
    func aiSearchForDomains(hint: String) async throws -> [DomainToPurchase]
    func getDomainsSuggestions(hint: String?) async throws -> [DomainToPurchaseSuggestion]
    
    func authoriseWithWallet(_ wallet: UDWallet, toPurchaseDomains domains: [DomainToPurchase]) async throws
    func getSupportedWalletsToMint() async throws -> [PurchasedDomainsWalletDescription]
    func reset() async
    
    func refreshCart() async throws 
    func addDomainsToCart(_ domains: [DomainToPurchase]) async throws
    func removeDomainsFromCart(_ domains: [DomainToPurchase]) async throws
    func purchaseDomainsInTheCartAndMintTo(wallet: PurchasedDomainsWalletDescription) async throws
}

enum PurchaseDomainCartStatus {
    case failedToAuthoriseWallet(UDWallet)
    case hasUnpaidDomains
    case failedToLoadCalculations(MainActorAsyncCallback)
    case ready(cart: PurchaseDomainsCart)
    
    var promoCreditsAvailable: Int {
        switch self {
        case .ready(let cart):
            return cart.promoCreditsAvailable
        default:
            return 0
        }
    }
    var storeCreditsAvailable: Int {
        switch self {
        case .ready(let cart):
            return cart.storeCreditsAvailable
        default:
            return 0
        }
    }
    var otherDiscountsApplied: Int {
        switch self {
        case .ready(let cart):
            return cart.appliedDiscountDetails.others
        default:
            return 0
        }
    }
    var discountsAppliedSum: Int {
        switch self {
        case .ready(let cart):
            return cart.appliedDiscountDetails.totalSum
        default:
            return 0
        }
    }
    var taxes: Int {
        switch self {
        case .ready(let cart):
            return cart.taxes
        default:
            return 0
        }
    }
    var totalPrice: Int {
        switch self {
        case .ready(let cart):
            return cart.totalPrice
        default:
            return 0
        }
    }
}

