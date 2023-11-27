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
                                           discountDetails: .init(storeCredits: 0,
                                                                  promoCredits: 0))
    
    var domains: [DomainToPurchase]
    var totalPrice: Int
    var discountDetails: DiscountDetails
    
    struct DiscountDetails {
        let storeCredits: Int
        let promoCredits: Int
    }
    
    func isDomainInCart(_ domain: DomainToPurchase) -> Bool {
        domains.first(where: { $0.name == domain.name }) != nil
    }
}