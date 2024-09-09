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
    
    init?(chainShortCode: String) {
        switch chainShortCode.uppercased().trimmedSpaces {
        case "ETH":
            self = .Ethereum
        case "MATIC":
            self = .Matic
        case "BASE":
            self = .Base
        case "BTC":
            self = .Bitcoin
        case "SOL":
            self = .Solana
        default: return nil
        }
    }
    
    init?(fullName: String) {
        switch fullName.trimmedSpaces {
        case "Ethereum":
            self = .Ethereum
        case "Polygon":
            self = .Matic
        case "Base":
            self = .Base
        case "Bitcoin":
            self = .Bitcoin
        case "Solana":
            self = .Solana
        default: return nil
        }
    }
}

