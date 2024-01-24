//
//  UnsConfigManager.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 26.12.2021.
//

import Foundation

struct UnsConfigManager {
    enum ConfigError: String, LocalizedError {
        case failedParsingUnsConfig
        
        public var errorDescription: String? {
            return rawValue
        }
    }
    
    // keys
    static let unsRegistryName = "UNSRegistry"
    static let cnsRegistryName = "CNSRegistry"
    static let proxyReaderName = "ProxyReader"
    static let resolverName = "Resolver"

    enum ConfigFileUsage: String {
        case uns_config = "uns-config"
        
        var filename: String {
            self.rawValue
        }
    }
    
    struct Contracts {
        let cnsRegistryAddress: HexAddress
        let unsRegistryAddress: HexAddress
        let proxyReader: HexAddress
        let resolverAddress: HexAddress
    }
    
    struct UnsNetworkConfigJson: Decodable {
        let version: String
        let networks: [String: UnsContractsEntry]
    }

    struct UnsContractsEntry: Decodable {
        let contracts: [String: UnsContractAddressEntry]
    }
    
    struct UnsContractAddressEntry: Decodable {
        let address: String
        let implementation: String?
        let legacyAddresses: [String]
        let deploymentBlock: String
    }

    static func getContractsL1(_ env: BlockchainEnvironment = NetworkConfig.currentEnvironment) -> Contracts? {
        guard let contractsContainer = Self.parseL1ContractAddresses(env) else {
                  Debugger.printFailure("Failed to parse contract addressed", critical: true)
                  return nil
              }
        return createContracts(from: contractsContainer)
    }
    
    static func getontractsL2(_ env: BlockchainEnvironment = NetworkConfig.currentEnvironment) -> Contracts? {
        guard let contractsContainer = Self.parseL2ContractAddresses(env) else {
                  Debugger.printFailure("Failed to parse contract addressed", critical: true)
                  return nil
              }
        return createContracts(from: contractsContainer)
    }
    
    static func createContracts(from contractsContainer: [String: UnsContractAddressEntry]) -> Contracts? {
        guard let cnsRegistry = contractsContainer[Self.cnsRegistryName]?.address,
              let unsRegistry = contractsContainer[Self.unsRegistryName]?.address,
              let proxyReader = contractsContainer[Self.proxyReaderName]?.address,
              let resolver = contractsContainer[Self.resolverName]?.address else {
                  Debugger.printFailure("Failed to parse contract addressed", critical: true)
                  return nil
              }
        return Contracts(cnsRegistryAddress: cnsRegistry,
                         unsRegistryAddress: unsRegistry,
                         proxyReader: proxyReader,
                         resolverAddress: resolver)
    }
         
    static func parseL1ContractAddresses(_ env: BlockchainEnvironment = NetworkConfig.currentEnvironment) -> [String: UnsContractAddressEntry]? {
        let networkId = env.getBlockchainConfigData().l1.id
        return parseUnsContractAddresses(blockchainIndex: networkId)
    }
    
    static func parseL2ContractAddresses(_ env: BlockchainEnvironment = NetworkConfig.currentEnvironment) -> [String: UnsContractAddressEntry]? {
        let networkId = env.getBlockchainConfigData().l2.id
        return parseUnsContractAddresses(blockchainIndex: networkId)
    }
    
    static func parseUnsContractAddresses(blockchainIndex: Int) -> [String: UnsContractAddressEntry]? {
        let bundler = Bundle.main
        if let filePath = bundler.url(forResource: ConfigFileUsage.uns_config.filename, withExtension: "json") {
            guard let data = try? Data(contentsOf: filePath) else { return nil }
            guard let info = try? JSONDecoder().decode(UnsNetworkConfigJson.self, from: data) else { return nil }
            guard let currentNetwork = info.networks[String(blockchainIndex)] else {
                return nil
            }
            return currentNetwork.contracts
        }
        return nil
    }
    
    static func getBlockchainNameForClient(by id: Int) -> String {
        BlockchainNetwork(rawValue: id)?.nameForClient ?? "not defined by chainId:\(id)"
    }
    
    enum BlockchainEnvironment {
        case mainnet
        case testnet
        
        var l1Network: BlockchainNetwork {
            switch self {
            case .mainnet:
                return .ethMainnet
            case .testnet:
                return .ethGoerli
            }
        }
        
        var l2Network: BlockchainNetwork {
            switch self {
            case .mainnet:
                return .polygonMainnet
            case .testnet:
                return .polygonMumbai
            }
        }
        
        func getBlockchainConfigData() -> BlockchainConfigData {
            BlockchainConfigData(environment: self)
        }
    }
    
    enum BlockchainLayerId {
        case l1
        case l2
    }
    
    enum Error: Swift.Error {
        case invalidChainId
        case unsupportedBlockchainType
    }
    
    static func getBlockchainType(from chainId: Int?) throws -> BlockchainType {
        let main = BlockchainConfigData(environment: .mainnet)
        let test = BlockchainConfigData(environment: .testnet)
        
        switch chainId {
        case main.l1.id, test.l1.id: return .Ethereum
        case main.l2.id, test.l2.id: return .Matic
        default:
            Debugger.printFailure("Invalid chain id for UnsConfig: \(String(describing: chainId))", critical: false)
            throw Error.invalidChainId
        }
    }
    
    struct BlockchainConfigData: Equatable {
        let l1: BlockchainNetwork
        let l2: BlockchainNetwork
        
        init(environment: BlockchainEnvironment) {
            self.init(l1: environment.l1Network, l2: environment.l2Network)
        }
        
        init(l1: BlockchainNetwork, l2: BlockchainNetwork) {
            self.l1 = l1
            self.l2 = l2
        }
        
        func getNetworkId(type: BlockchainType) -> Int?{
            switch type {
            case .Ethereum: return self.l1.id
            case .Matic: return self.l2.id
            default: Debugger.printFailure("Wrong network selected: \(type)", critical: true)
                return nil
            }
        }
    }
}
