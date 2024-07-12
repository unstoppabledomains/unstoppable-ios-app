//
//  BlockchainType+Extension.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.06.2024.
//

import UIKit

extension BlockchainType {
    
    enum Chain: Int, CaseIterable {
        case ethMainnet = 1
        case ethSepolia = 11155111
        case polygonMainnet = 137
        case polygonAmoy = 80002
        
        case baseMainnet = 8453
        case baseSepolia = 84532
        
        var id: Int { rawValue }
        
        var nameForClient: String {
            switch self {
            case .ethMainnet:
                return "Ethereum"
            case .ethSepolia:
                return "Ethereum: Sepolia"
            case .polygonMainnet:
                return "Polygon"
            case .polygonAmoy:
                return "Polygon: Amoy"
            case .baseMainnet:
                return "Base: Mainnet"
            case .baseSepolia:
                return "Base: Sepolia"
            }
        }
        
        var name: String {
            switch self {
            case .ethMainnet:
                return "mainnet"
            case .ethSepolia:
                return "sepolia"
            case .polygonMainnet:
                return "polygon-mainnet"
            case .polygonAmoy:
                return "polygon-amoy"
            case .baseMainnet:
                return "base-mainnet"
            case .baseSepolia:
                return "base-sepolia"
            }
        }
        
        func identifyBlockchainType() -> BlockchainType {
            switch self {
            case .ethMainnet, .ethSepolia:
                return .Ethereum
            case .polygonMainnet, .polygonAmoy:
                return .Matic
            case .baseMainnet, .baseSepolia:
                return .Base
            }
        }
    }
    
    static func getType(abbreviation: String?) throws -> Self {
        guard let abbreviation = abbreviation else { throw InitError.invalidBlockchainAbbreviation }
        guard let result = Self.blockchainType(chainShortCode: abbreviation) else {
            throw InitError.invalidBlockchainAbbreviation
        }
        return result
    }
    
    var icon: UIImage {
        switch self {
        case .Ethereum:
            return UIImage(named: String.BlockChainIcons.ethereum.rawValue)!
        case .Matic:
            return UIImage(named: String.BlockChainIcons.matic.rawValue)!
        case .Base:
            return .baseIcon
        case .Bitcoin:
            return .bitcoinIcon
        case .Solana:
            return .solanaIcon
            
        }
    }
    
    func supportedChainId(isTestNet: Bool) -> Int {
        switch self {
        case .Ethereum:
            return isTestNet ? Chain.ethSepolia.id : Chain.ethMainnet.id // Sepolia or Mainnet
        case .Matic:
            return isTestNet ? Chain.polygonAmoy.id : Chain.polygonMainnet.id // Amoy or Polygon
        case .Base:
            return isTestNet ? Chain.baseSepolia.id : Chain.baseMainnet.id // Base Sepolia or Base Mainnet
        case .Bitcoin:
            return 0 // TODO:
        case .Solana:
            return 0 // TODO:
        }
    }
    
    func supportedChainId(env: UnsConfigManager.BlockchainEnvironment) -> Int {
        supportedChainId(isTestNet: env == .testnet)
    }
    
    var chainIcon: UIImage {
        switch self {
        case .Ethereum:
                .ethereumIcon
        case .Matic:
                .polygonIcon
        case .Base:
                .baseIcon
        case .Bitcoin:
                .bitcoinIcon
        case .Solana:
                .solanaIcon
        }
    }
}
