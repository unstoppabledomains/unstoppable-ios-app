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
               version: "",
               expandedTicker: "crypto.ETH",
               regexPattern: BlockchainType.Ethereum.regexPattern),
         .init(ticker: "MATIC",
               version: "",
               expandedTicker: "crypto.MATIC",
               regexPattern: BlockchainType.Matic.regexPattern),
         .init(ticker: "BTC",
               version: "",
               expandedTicker: "crypto.BTC.address",
               regexPattern: BlockchainType.Bitcoin.regexPattern)]
    }
    
    func refreshCurrencies(version: String) {
        
    }
}
