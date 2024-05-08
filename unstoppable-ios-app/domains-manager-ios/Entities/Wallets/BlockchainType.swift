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
    static func getType(abbreviation: String?) throws -> Self {
        guard let abbreviation = abbreviation else { throw InitError.invalidBlockchainAbbreviation }
        let sample = abbreviation.lowercased().trimmed
        guard let result = Self.cases.first(where: {$0.rawValue.lowercased() == sample} ) else {
            throw InitError.invalidBlockchainAbbreviation
        }
        return result
    }
    
    static let supportedCases: [BlockchainType] = [.Ethereum, .Matic]
    
    var icon: UIImage {
        switch self {
        case .Ethereum:
            return UIImage(named: String.BlockChainIcons.ethereum.rawValue)!
        case .Matic:
            return UIImage(named: String.BlockChainIcons.matic.rawValue)!
        }
    }
    
    var fullName: String {
        switch self {
        case .Ethereum:
            return "Ethereum"
        case .Matic:
            return "Polygon"
        }
    }
    
    func supportedChainId(isTestNet: Bool) -> Int {
        switch self {
        case .Ethereum:
            return isTestNet ? BlockchainNetwork.ethSepolia.id : BlockchainNetwork.ethMainnet.id // Sepolia or Mainnet
        case .Matic:
            return isTestNet ? BlockchainNetwork.polygonAmoy.id : BlockchainNetwork.polygonMainnet.id // Amoy or Polygon
        }
    }
    
    func supportedChainId(env: UnsConfigManager.BlockchainEnvironment) -> Int {
        supportedChainId(isTestNet: env == .testnet)
    }

    
    enum InitError: Error {
        case invalidBlockchainAbbreviation
    }
}
