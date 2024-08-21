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
        formatter.minimumFractionDigits = 2
        formatter.currencyDecimalSeparator = "."
        formatter.currencyGroupingSeparator = ","
        return formatter
    }()
}

func formatCartPrice(_ price: Int) -> String {
    let price = PaymentConfiguration.centsIntoDollars(cents: price)
    return formatCartPrice(price)
}

func formatCartPrice(_ price: Double) -> String {
    return PaymentConfiguration.cartPriceFormatter.string(from: price as NSNumber)!
}
