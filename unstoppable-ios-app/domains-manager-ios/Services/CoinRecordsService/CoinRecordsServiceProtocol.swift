//
//  CoinRecordsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation

protocol CoinRecordsServiceProtocol {
    func getCurrencies() async -> [CoinRecord]
    func refreshCurrencies(version: String)
}
