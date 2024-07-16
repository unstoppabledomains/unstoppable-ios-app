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
//    var icon: UIImage { get }
}

enum BlockchainType: BlockchainProtocol {    
    
    case Ethereum
    case Matic
    case Base
    
    case Bitcoin
    case Solana
    
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
            
        case .Bitcoin:
            return "BTC"
        case .Solana:
            return "SOL"
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
            
        case .Bitcoin:
            return "Bitcoin"
        case .Solana:
            return "Solana"
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
            
        case "BTC":
            return .Bitcoin
        case "SOL":
            return .Solana
        default: return nil
        }
    }
    
    static func blockchainType(fullName: String) -> BlockchainType? {
        switch fullName.trimmedSpaces {
        case "Ethereum":
            return .Ethereum
        case "Polygon":
            return .Matic
        case "Base":
            return .Base
            
        case "Bitcoin":
            return .Bitcoin
        case "Solana":
            return .Solana
        default: return nil
        }
    }
}

