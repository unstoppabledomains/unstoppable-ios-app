//
//  CoinRegexPattern.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.06.2024.
//

import Foundation

enum CoinRegexPattern: String, CaseIterable {
    case ETH
    case SOL
    case BTC
}

extension CoinRegexPattern {
    var regex: String {
        switch self {
        case .ETH: "^0x[a-fA-F0-9]{40}$"
        case .SOL: "^[1-9A-HJ-NP-Za-km-z]{32,44}$"
        case .BTC: "^bc1[ac-hj-np-z02-9]{6,87}$|^[13][a-km-zA-HJ-NP-Z1-9]{25,39}$"
        }
    }
    
    func isStringMatchingRegex(_ string: String) -> Bool {
        string.isMatchingRegexPattern(regex)
    }
}
