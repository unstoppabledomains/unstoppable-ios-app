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
               regexPattern: CoinRegexPattern.eth.regex,
               isDeprecated: false),
         .init(ticker: "MATIC",
               version: nil,
               expandedTicker: "crypto.MATIC",
               regexPattern: CoinRegexPattern.eth.regex,
               isDeprecated: false),
         .init(ticker: "BTC",
               version: nil,
               expandedTicker: "crypto.BTC.address",
               regexPattern: CoinRegexPattern.btc.regex,
               isDeprecated: false)]
    }
    
    func refreshCurrencies(version: String) {
        
    }
}
