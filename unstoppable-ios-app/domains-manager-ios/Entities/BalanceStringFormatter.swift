//
//  BalanceStringFormatter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation

struct BalanceStringFormatter {
    
    static func tokenBalanceString(_ token: BalanceTokenUIDescription) -> String {
        tokenBalanceString(balance: token.balance,
                           symbol: token.symbol)
    }
    
    static func tokenBalanceString(balance: Double, 
                                   symbol: String) -> String {
        "\(balance.formattedBalance()) \(symbol)"
    }
    
    static func tokenFullBalanceString(balance: Double,
                                       symbol: String) -> String {
        "\(balance.formatted(toMaxNumberAfterComa: 8)) \(symbol)"
    }
    
    static func tokensBalanceUSDString(_ balance: Double) -> String {
        "$\(balance.formattedBalance())"
    }
    
}
