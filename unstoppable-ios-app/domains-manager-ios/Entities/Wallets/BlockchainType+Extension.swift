//
//  BlockchainType+Extension.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.06.2024.
//

import UIKit

extension BlockchainType {
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
                    return UIImage(named: String.BlockChainIcons.base.rawValue)!
        }
    }
    
    func supportedChainId(isTestNet: Bool) -> Int {
        switch self {
        case .Ethereum:
            return isTestNet ? BlockchainNetwork.ethSepolia.id : BlockchainNetwork.ethMainnet.id // Sepolia or Mainnet
        case .Matic:
            return isTestNet ? BlockchainNetwork.polygonAmoy.id : BlockchainNetwork.polygonMainnet.id // Amoy or Polygon
        case .Base:
            return isTestNet ? BlockchainNetwork.baseSepolia.id : BlockchainNetwork.baseMainnet.id // Base Sepolia or Base Mainnet
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
        }
    }
}

extension SemiSupportedBlockchainType {
    var chainIcon: UIImage {
        switch self {
        case .Bitcoin:
                .bitcoinIcon
        case .Solana:
                .solanaIcon
        case .Base:
                .baseIcon
        }
    }
}
