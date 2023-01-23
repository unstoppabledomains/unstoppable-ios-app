//
//  CurrencyExchangeRates.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 06.07.2022.
//

import Foundation

struct CurrencyExchangeRates {
    
    enum ExchangedCurrency: String {
        case Ether = "ETH"
        case Matic = "MATIC"
    }
    
    struct RateResponseUsd: Decodable {
        let USD: Double
    }
    
    struct Rates {
        let usdToEth: Double
        let usdToMatic: Double
    }
    
    static let tenMinutes: TimeInterval = 10 * 60
    
    static private var lastFetchTimeStamp: TimeInterval?
    static private var currentExchangeRates: Rates?
    
    private static func fetchRate(for currency: ExchangedCurrency) async throws -> Double {
        let currencyName = currency.rawValue
        guard let url = URL(string: "https://min-api.cryptocompare.com/data/price?fsym=\(currencyName)&tsyms=USD") else { throw Error.incorrectURL }
        let data = try await NetworkService().fetchData(for: url,
                                                        method: .get)
        let rate = try JSONDecoder().decode(RateResponseUsd.self, from: data)
        return rate.USD
    }
    
    static func getRates(forceRefresh: Bool) async throws -> Rates {
        let timeStamp = Date().timeIntervalSinceReferenceDate
        if forceRefresh ||
           timeStamp - (Self.lastFetchTimeStamp ?? 0) > Self.tenMinutes {
            let asyncResponses = try await (eth: fetchRate(for: .Ether),
                                            matic: fetchRate(for: .Matic))
            
            let eth = asyncResponses.eth
            let matic = asyncResponses.matic
            
            Self.currentExchangeRates = Rates(usdToEth: eth, usdToMatic: matic)
            Self.lastFetchTimeStamp = timeStamp
        }
        
        guard let currentExchangeRates = Self.currentExchangeRates else {
            Debugger.printFailure("currentExchangeRates not assigned and did not throw error", critical: true)
            throw Error.noData
        }
        return currentExchangeRates
    }
}

extension CurrencyExchangeRates {
    enum Error: Swift.Error {
        case incorrectURL
        case noData
        case decodingError
    }
}
