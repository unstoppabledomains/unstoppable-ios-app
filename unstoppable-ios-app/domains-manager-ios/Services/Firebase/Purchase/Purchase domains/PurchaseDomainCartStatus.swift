//
//  PurchaseDomainCartStatus.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import Foundation

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

