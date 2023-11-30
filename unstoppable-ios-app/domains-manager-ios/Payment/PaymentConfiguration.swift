//
//  PaymentConfiguration-PROD.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.05.2021.
//

import Foundation

public class PaymentConfiguration {
    static let cartPaymentLocale = Locale(identifier: "es_CL")
    static let usdCurrencyLabel = "USD"
    static let usdCurrencySymbol = "$"
    static let usCountryCode = "US"
        
    static func centsIntoDollars(cents: Int) -> Double {
        Double(cents) / 100.0
    }
    
    static let cartPriceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = PaymentConfiguration.cartPaymentLocale
        formatter.currencyCode = PaymentConfiguration.usdCurrencyLabel
        formatter.currencySymbol = PaymentConfiguration.usdCurrencySymbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.currencyDecimalSeparator = "."
        return formatter
    }()
}

func formatCartPrice(_ price: Int) -> String {
    let price = PaymentConfiguration.centsIntoDollars(cents: price) 
    return PaymentConfiguration.cartPriceFormatter.string(from: price as NSNumber)!
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
