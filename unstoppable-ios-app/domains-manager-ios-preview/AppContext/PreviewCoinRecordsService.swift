//
//  PreviewCoinRecordsService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation
import Combine

final class CoinRecordsService: CoinRecordsServiceProtocol {
    private(set) var eventsPublisher = PassthroughSubject<CoinRecordsEvent, Never>()

    func getCurrencies() async -> [CoinRecord] {
        [.init(ticker: "ETH",
               network: "",
               expandedTicker: "crypto.ETH",
               regexPattern: BlockchainType.Ethereum.regexPattern),
         .init(ticker: "MATIC",
               network: "",
               expandedTicker: "crypto.MATIC",
               regexPattern: BlockchainType.Matic.regexPattern),
         .init(ticker: "BTC",
               network: "",
               expandedTicker: "crypto.BTC.address",
               regexPattern: BlockchainType.Bitcoin.regexPattern)]
    }
    
    func refreshCurrencies(version: String) {
        
    }
}
