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
    case Base = "BASE"
    
    static let cases = Self.allCases
    
    enum InitError: Error {
        case invalidBlockchainAbbreviation
    }
    
    var shortCode: String { rawValue }
    
    var fullName: String {
        switch self {
        case .Ethereum:
            return "Ethereum"
        case .Matic:
            return "Polygon"
        case .Base:
            return "Base"
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
