//
//  PreviewCoinRecordsService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation

final class CoinRecordsService: CoinRecordsServiceProtocol {
    
    func getCurrencies() async -> [CoinRecord] {
        [.init(ticker: "ETH",
               version: nil,
               expandedTicker: "crypto.ETH", 
               regexPattern: Constants.ETHRegexPattern,
               isDeprecated: false),
         .init(ticker: "MATIC",
               version: nil,
               expandedTicker: "crypto.MATIC",
               regexPattern: Constants.ETHRegexPattern,
               isDeprecated: false),
         .init(ticker: "BTC",
               version: nil,
               expandedTicker: "crypto.BTC.address",
               regexPattern: "^bc1[ac-hj-np-z02-9]{6,87}$|^[13][a-km-zA-HJ-NP-Z1-9]{25,39}$",
               isDeprecated: false)]
    }
    
    func refreshCurrencies(version: String) {
        
    }
}
