//
//  StripeService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.03.2023.
//

import Foundation
import Stripe

final class StripeService {
    
    static let shared = StripeService()
    
    private init() { }
    
}

// MARK: - Open methods
extension StripeService {
    func setup() {
        let key: String
        switch User.instance.getSettings().networkType {
        case .mainnet:
            key = PaymentConfiguration.Stripe.defaultPublishableKey
        case .testnet:
            key = PaymentConfiguration.Stripe.developmentKey
        }
        StripeAPI.defaultPublishableKey = key
    }
}
