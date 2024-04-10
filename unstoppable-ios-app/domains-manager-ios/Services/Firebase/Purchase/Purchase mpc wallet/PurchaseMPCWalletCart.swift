//
//  PurchaseMPCWalletCart.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import Foundation

struct PurchaseMPCWalletCart {
    
    static let empty = PurchaseMPCWalletCart(totalPrice: 0,
                                             taxes: 0,
                                             storeCreditsAvailable: 0,
                                             promoCreditsAvailable: 0,
                                             appliedDiscountDetails: .init(storeCredits: 0,
                                                                           promoCredits: 0,
                                                                           others: 0))
    
    var totalPrice: Int
    var taxes: Int
    let storeCreditsAvailable: Int
    let promoCreditsAvailable: Int
    var appliedDiscountDetails: AppliedDiscountDetails
    
    struct AppliedDiscountDetails {
        let storeCredits: Int
        let promoCredits: Int
        var others: Int
        
        var totalSum: Int { storeCredits + promoCredits + others }
    }
}
