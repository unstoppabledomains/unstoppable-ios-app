//
//  BalanceStringFormatter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation

struct BalanceStringFormatter {
    
    static func tokensBalanceString(_ balance: Double) -> String {
        "$\(balance.formatted(toMaxNumberAfterComa: 2))"
    }
    
}
