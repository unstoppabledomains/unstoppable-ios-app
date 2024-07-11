//
//  BlockchainType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

protocol BlockchainProtocol: CaseIterable, Codable, Hashable {
    var fullName: String { get }
    var shortCode: String { get }
}

enum BlockchainType: BlockchainProtocol {
    
    case Ethereum //= "ETH"
    case Matic //= "MATIC"
    case Base //= "BASE"
    
    static let cases = Self.allCases
    
    enum InitError: Error {
        case invalidBlockchainAbbreviation
    }
    
    var shortCode: String {
        switch self {
        case .Ethereum:
            return "ETH"
        case .Matic:
            return "MATIC"
        case .Base:
            return "BASE"
        }
    }
    
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
    
    static func blockchainType(chainShortCode: String) -> BlockchainType? {
        switch chainShortCode.uppercased().trimmedSpaces {
        case "ETH":
            return .Ethereum
        case "MATIC":
            return .Matic
        case "BASE":
            return .Base
        default: return nil
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
