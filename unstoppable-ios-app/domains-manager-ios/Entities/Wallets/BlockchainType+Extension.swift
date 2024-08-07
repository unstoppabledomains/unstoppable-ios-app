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
        
        case solanaMainnet = 101
        case solanaTestnet = 102
        
        case bitcoinMainnet = -1
        case bitcoinTestnet = -2
        
        var id: Int { rawValue }
        
        var fullName: String {
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
                
            case .solanaMainnet:
                return "Solana"
            case .solanaTestnet:
                return "Solana Testnet"
                
            case .bitcoinMainnet:
                return "Bitcoin"
            case .bitcoinTestnet:
                return "Bitcoin Testnet"
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
                
            case .solanaMainnet:
                return "solana"
            case .solanaTestnet:
                return "solana-testnet"
                
            case .bitcoinMainnet:
                return "bitcoin"
            case .bitcoinTestnet:
                return "bitcoin-testnet"
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
            case .solanaMainnet, .solanaTestnet:
                 return .Solana
            case .bitcoinMainnet, .bitcoinTestnet:
                 return .Bitcoin
            }
        }
        
        func identifyEnvironment() -> UnsConfigManager.BlockchainEnvironment {
            switch self {
            case .ethMainnet, .polygonMainnet, .baseMainnet, .solanaMainnet, .bitcoinMainnet:
                 return .mainnet
                
            case .ethSepolia, .polygonAmoy, .baseSepolia, .solanaTestnet, .bitcoinTestnet:
                 return .testnet
            }
        }
    }
    
    static func resolve(shortCode: String?) throws -> Self {
        guard let abbreviation = shortCode else { throw InitError.invalidBlockchainAbbreviation }
        guard let result = Self(chainShortCode: abbreviation) else {
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
    
    func resolveChain(isTestNet: Bool) -> Chain {
        switch self {
        case .Ethereum:
            return isTestNet ? Chain.ethSepolia : Chain.ethMainnet // Sepolia or Mainnet
        case .Matic:
            return isTestNet ? Chain.polygonAmoy : Chain.polygonMainnet // Amoy or Polygon
        case .Base:
            return isTestNet ? Chain.baseSepolia : Chain.baseMainnet // Base Sepolia or Base Mainnet
        case .Bitcoin:
            return isTestNet ? Chain.bitcoinTestnet : Chain.bitcoinMainnet
        case .Solana:
            return isTestNet ? Chain.solanaTestnet : Chain.solanaMainnet
        }
    }
    
    func resolveChain(env: UnsConfigManager.BlockchainEnvironment) -> Chain {
        resolveChain(isTestNet: env == .testnet)
    }

    func resolveChainId(isTestNet: Bool) -> Int {
        resolveChain(isTestNet: isTestNet).id
    }
    
    func resolveChainId(env: UnsConfigManager.BlockchainEnvironment) -> Int {
        resolveChain(env: env).id
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

extension BlockchainType {
    var isEVMNetwork: Bool {
        switch self {
        case .Ethereum, .Matic, .Base: true
        case .Bitcoin: false
        case .Solana: false
        }
    }
    
    var regexPattern: String {
        switch self {
        case .Ethereum, .Matic, .Base: "^0x[a-fA-F0-9]{40}$"
        case .Bitcoin: "^bc1[ac-hj-np-z02-9]{6,87}$|^[13][a-km-zA-HJ-NP-Z1-9]{25,39}$"
        case .Solana: "^[1-9A-HJ-NP-Za-km-z]{32,44}$"
        }
    }
    
    func isStringMatchingRegex(_ string: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", regexPattern)
        
        return predicate.evaluate(with: string)
    }
}
