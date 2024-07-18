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
               regexPattern: BlockchainType.Ethereum.regexPattern,
               isDeprecated: false),
         .init(ticker: "MATIC",
               version: nil,
               expandedTicker: "crypto.MATIC",
               regexPattern: BlockchainType.Matic.regexPattern,
               isDeprecated: false),
         .init(ticker: "BTC",
               version: nil,
               expandedTicker: "crypto.BTC.address",
               regexPattern: BlockchainType.Bitcoin.regexPattern,
               isDeprecated: false)]
    }
    
    func refreshCurrencies(version: String) {
        
    }
}
