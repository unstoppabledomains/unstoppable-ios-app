//
//  PaymentConfiguration-PROD.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.05.2021.
//

import Foundation

public class PaymentConfiguration {
    static let usdCurrencyLabel = "USD"
    static let usCountryCode = "US"
        
    static func centsIntoDollars(cents: Int) -> Double {
        Double(cents) / 100.0
    }
}

extension DomainItem {
    /// This method puts a rule whether or not the domains requires payment for a critical trnasaction.
    /// True means that the app will launch Apple Pay flow and will depend on the backend
    /// - Returns: Bool
    func doesRequirePayment() -> Bool {
        switch self.getBlockchainType() {
        case .Ethereum: return true
        case .Zilliqa, .Matic: return false
        }
    }
}
