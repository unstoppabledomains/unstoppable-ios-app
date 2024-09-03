//
//  CoinRecord.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import Foundation

struct CoinRecord: Hashable, Codable {
    
    let ticker: String
    let expandedTicker: String
    let network: String
    let fullName: String?
    let regexPatterns: [String]
    let isPrimaryChain: Bool
    let mapping: Mapping?
    let parents: [Parent]
    
    init(ticker: String,
         network: String,
         expandedTicker: String,
         regexPattern: String?,
         fullName: String? = nil,
         mapping: Mapping? = nil,
         parents: [Parent] = []) {
        self.ticker = ticker
        self.network = network
        self.expandedTicker = expandedTicker
        self.mapping = mapping
        self.parents = parents
        
        if let regexPattern {
            self.regexPatterns = [regexPattern]
        } else {
            self.regexPatterns = [BlockchainType.Ethereum.regexPattern]
        }
        
        self.isPrimaryChain = Self.primaryNetworksMap[ticker] == network
        self.fullName = fullName ?? ticker
    }
    
}

// MARK: - CustomStringConvertible
extension CoinRecord: CustomStringConvertible {
    var description: String {
        return "\(self.ticker) (\(network))"
    }
}

// MARK: - Comparable
extension CoinRecord: Comparable {
    static func < (lhs: CoinRecord, rhs: CoinRecord) -> Bool {
        lhs.expandedTicker < rhs.expandedTicker
    }
}

// MARK: - Open methods
extension CoinRecord {
    var name: String { ticker }
    var displayName: String { fullName ?? name }
    
    func validate(_ proposedAddress: String) -> Bool {
        regexPatterns.first(where: { proposedAddress.isMatchingRegexPattern($0) }) != nil
    }
    
    func isMatching(recordKey: String) -> Bool {
        /// Check record key is in new format
        if expandedTicker == recordKey {
            return true
        }
        
        /// Check record key is in old format
        return mapping?.from.first(where: { $0 == recordKey }) != nil
    }
    
    func getNewAndLegacyTickers() -> [String] {
        var tickers = [expandedTicker]
        if let legacyTicker = mapping?.to {
            tickers.append(legacyTicker)
        }
        return tickers
    }
}

// MARK: - Open methods
extension CoinRecord {
    struct Mapping: Codable, Hashable {
        let isPreferred: Bool
        let from: [String]
        let to: String
    }
    
    struct Parent: Codable, Hashable {
        let key: String
        let name: String
        let shortName: String
        let subType: String
    }
}

// MARK: - Private methods
private extension CoinRecord {
    private static let primaryNetworksMap: [String : String] = ["ELA" : "ELA",
                                                                "FTM" : "FTM",
                                                                "FUSE" : "FUSE",
                                                                "MATIC" : "MATIC",
                                                                "ETH" : "ETH",
                                                                "UNI" : "ETH",
                                                                "BUSD" : "BSC",
                                                                "USDT" : "ETH",
                                                                "WBTC" : "ETH",
                                                                "AAVE" : "ETH",
                                                                "SHIB" : "ETH",
                                                                "CEL" : "ETH",
                                                                "GALA" : "ETH",
                                                                "B2M" : "ETH",
                                                                "CAKE" : "BSC",
                                                                "SAFEMOON" : "BSC",
                                                                "TEL" : "ETH",
                                                                "SUSHI" : "ETH",
                                                                "TUSD" : "ETH",
                                                                "HBTC" : "ETH",
                                                                "SNX" : "ETH",
                                                                "HOT" : "ETH",
                                                                "NEXO" : "ETH",
                                                                "MANA" : "ETH",
                                                                "MDX" : "BSC",
                                                                "LUSD" : "ETH",
                                                                "GRT" : "ETH",
                                                                "HUSD" : "ETH",
                                                                "CRV" : "ETH",
                                                                "WRX" : "BNB",
                                                                "LPT" : "ETH",
                                                                "BAKE" : "BSC",
                                                                "1INCH" : "ETH",
                                                                "WOO" : "ETH",
                                                                "OXY" : "SOL",
                                                                "REN" : "ETH",
                                                                "RENBTC" : "ETH",
                                                                "FEG" : "ETH",
                                                                "MIR" : "ETH",
                                                                "PAXG" : "ETH",
                                                                "REEF" : "ETH",
                                                                "BAND" : "ETH",
                                                                "INJ" : "ETH",
                                                                "SAND" : "ETH",
                                                                "CTSI" : "ETH",
                                                                "ANC" : "LUNA",
                                                                "IQ" : "ETH",
                                                                "SUSD" : "ETH",
                                                                "SRM" : "SOL",
                                                                "KEEP" : "ETH",
                                                                "ALPHA" : "BSC",
                                                                "DODO" : "BSC",
                                                                "KNCL" : "ETH",
                                                                "SXP" : "ETH",
                                                                "UBT" : "ETH",
                                                                "STORJ" : "ETH",
                                                                "DPI" : "ETH",
                                                                "DOG" : "ETH",
                                                                "0ZK" : "0ZK",
                                                                "SWEAT" : "NEAR",
                                                                "FET" : "FET",
                                                                "BNB" : "BSC",
                                                                "USDC" : "ETH",
                                                                "MCONTENT" : "BSC",
                                                                "HI" : "ETH",
                                                                "WETH" : "ETH"]
}
