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
         version: String,
         expandedTicker: String,
         regexPattern: String?,
         fullName: String? = nil,
         mapping: Mapping? = nil,
         parents: [Parent] = []) {
        self.ticker = ticker
        self.network = version
        self.expandedTicker = expandedTicker
        self.mapping = mapping
        self.parents = parents
        
        if let regexPattern {
            self.regexPatterns = [regexPattern]
        } else {
            self.regexPatterns = [BlockchainType.Ethereum.regexPattern]
        }
        
        self.isPrimaryChain = version == ticker
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

