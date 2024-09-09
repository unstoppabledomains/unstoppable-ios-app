//
//  CoinRecordsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation
import Combine

protocol CoinRecordsServiceProtocol {
    var eventsPublisher: PassthroughSubject<CoinRecordsEvent, Never> { get }
    
    func getCurrencies() async -> [CoinRecord]
    func refreshCurrencies(version: String)
}

enum CoinRecordsEvent {
    case didUpdateCoinsList
}
