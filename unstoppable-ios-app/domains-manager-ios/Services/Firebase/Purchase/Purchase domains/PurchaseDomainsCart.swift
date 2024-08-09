//
//  PurchaseDomainsCart.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import Foundation

struct PurchaseDomainsCart {
    
    static let empty = PurchaseDomainsCart(domains: [],
                                           totalPrice: 0,
                                           taxes: 0,
                                           storeCreditsAvailable: 0,
                                           promoCreditsAvailable: 0,
                                           appliedDiscountDetails: .init(storeCredits: 0,
                                                                         promoCredits: 0,
                                                                         others: 0))
    
    var domains: [DomainToPurchase]
    var totalPrice: Int
    let subtotalPrice: Int
    var taxes: Int
    let storeCreditsAvailable: Int
    let promoCreditsAvailable: Int
    var appliedDiscountDetails: AppliedDiscountDetails
    
    init(domains: [DomainToPurchase], totalPrice: Int, taxes: Int, storeCreditsAvailable: Int, promoCreditsAvailable: Int, appliedDiscountDetails: AppliedDiscountDetails) {
        self.domains = domains
        self.totalPrice = totalPrice
        self.subtotalPrice = domains.reduce(0, { $0 + $1.price })
        self.taxes = taxes
        self.storeCreditsAvailable = storeCreditsAvailable
        self.promoCreditsAvailable = promoCreditsAvailable
        self.appliedDiscountDetails = appliedDiscountDetails
    }
    
    struct AppliedDiscountDetails {
        let storeCredits: Int
        let promoCredits: Int
        var others: Int
        
        var totalSum: Int { storeCredits + promoCredits + others }
    }
    
    func isDomainInCart(_ domain: DomainToPurchase) -> Bool {
        domains.first(where: { $0.name == domain.name }) != nil
    }
}
