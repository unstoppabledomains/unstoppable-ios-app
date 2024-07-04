//
//  BlockchainType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

enum BlockchainType: String, CaseIterable, Codable, Hashable {
    case Ethereum = "ETH"
    case Matic = "MATIC"
    
    static let cases = Self.allCases
    static let supportedCases: [BlockchainType] = [.Ethereum, .Matic]
    
    enum InitError: Error {
        case invalidBlockchainAbbreviation
    }
    
    var fullName: String {
        switch self {
        case .Ethereum:
            return "Ethereum"
        case .Matic:
            return "Polygon"
        }
    }
}

enum SemiSupportedBlockchainType: String, CaseIterable, Codable, Hashable {
    case Bitcoin = "BTC"
    case Solana = "SOL"
    case Base = "BASE"
    
    var fullName: String {
        switch self {
        case .Bitcoin:
            return "Bitcoin"
        case .Solana:
            return "Solana"
        case .Base:
            return "Base"
        }
    }
}
