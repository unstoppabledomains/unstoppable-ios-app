//
//  CryptoSender+Entities.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.04.2024.
//

import Foundation

// Unified container for the token amount.
// Init with units, gwei's or wei's
// Read in units, gwei's or wei's
struct EVMCoinAmount: OnChainCountable {
    static let Billion = 1_000_000_000.0
    private let gweiTotal: Double
    
    init(units: Double) {
        self.gweiTotal = units * Self.Billion
    }
    
    init(gwei: Double) {
        self.gweiTotal = gwei
    }
    
    init(gwei: Int) {
        self.gweiTotal = Double(gwei)
    }
    
    init(wei: UDBigUInt) {
        self.gweiTotal = Double(wei) / Self.Billion
    }
    
    var units: Double {
        gweiTotal / Self.Billion
    }
    
    var gwei: Double {
        gweiTotal
    }
    
    var wei: UDBigUInt { // can only be integer and may be very big
        UDBigUInt(gweiTotal * Self.Billion)
    }
    
    func getOnChainCountable() -> UDBigUInt {
        self.wei
    }
}

protocol DecimalPointFloatable {
    var decimals: UInt8 { get }
}

struct ERC20Token: DecimalPointFloatable, OnChainCountable {
    var elementaryUnits: UDBigUInt
    var decimals: UInt8
    
    init(units: Double, decimals: UInt8) {
        self.decimals = decimals
        self.elementaryUnits = UDBigUInt(units * pow(10, Double(decimals)))
    }
    
    func getOnChainCountable() -> UDBigUInt {
        elementaryUnits
    }
    
    var units: Double {
        Double(elementaryUnits) / pow(10, Double(decimals))
    }
}

protocol OnChainCountable {
    func getOnChainCountable() -> UDBigUInt
}

struct EstimatedGasPrices {
    let normal: EVMCoinAmount
    let fast: EVMCoinAmount
    let urgent: EVMCoinAmount
    
    func getPriceForSpeed(_ txSpeed: CryptoSendingSpec.TxSpeed) -> EVMCoinAmount {
        switch txSpeed {
        case .normal:
            return normal
        case .fast:
            return fast
        case .urgent:
            return urgent
        }
    }
}

struct ChainSpec {
    let chain: BlockchainType.Chain
    
    init(blockchainType: BlockchainType, env: UnsConfigManager.BlockchainEnvironment = .mainnet) {
        self.chain = blockchainType.supportedChain(env: env)
    }
    
    var id: Int {
        self.chain.id
    }
}

struct CryptoSendingSpec {
    enum TxSpeed {
        case normal, fast, urgent
    }
    
    let token: CryptoSender.SupportedToken
    let amount: OnChainCountable
    let speed: TxSpeed
    
    init(token: CryptoSender.SupportedToken, units: Double, speed: TxSpeed = .normal) throws {
        
        switch token {
        case .eth, .matic: self.amount = EVMCoinAmount(units: units)
        default: self.amount = ERC20Token(units: units, decimals: try token.getContractDecimals(for: .Ethereum))
        }
        
        self.token = token
        self.speed = speed
    }
}

extension CryptoSender {
    enum Error: Swift.Error {
        case sendingNotSupported
        case tokenNotSupportedOnChain
        case decimalsNotIdentified
        case failedFetchGasPrice
        case failedCreateSendTransaction
        case insufficientFunds
        case invalidAddresses
        case invalidTokenSymbol
        case invalidChainSymbol
    }
    
    enum SupportedToken: String {
        case eth = "ETH"
        case matic = "MATIC"
        case usdt = "USDT"
        case usdc = "USDC"
        case bnb = "BNB"
        case weth = "WETH"
        
        init(tokenSymbol: String) throws {
            guard let created = SupportedToken(rawValue: tokenSymbol.uppercased()) else {
                throw Error.invalidTokenSymbol
            }
            self = created
        }
        
//        typealias BlockchainTypeData = (mainnet: String,
//                                        testnet: String?,
//                                        decimals: UInt8)
//        typealias BlockchainTypeEntries = [BlockchainType : (mainnet: String,
//                                                             testnet: String?,
//                                                             decimals: UInt8)]
        
        static let contractArray: [CryptoSender.SupportedToken :
                                    [BlockchainType : (mainnet: String,
                                                                                         testnet: String?,
                                                                                         decimals: UInt8)]] =
        [
                .usdt: [.Ethereum: (mainnet: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
                                testnet: "0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0", // sepolia
                                decimals: 6),
                    .Matic: (mainnet: "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
                             testnet: nil, // amoy
                             decimals: 6)],
            
                .bnb: [.Ethereum: (mainnet: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52",
                                   testnet: nil, // sepolia
                                   decimals: 18),
                       .Matic: (mainnet: "0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3",
                                testnet: nil, // amoy
                                decimals: 18)],
            
                .usdc: [.Ethereum: (mainnet: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
                                    testnet: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238", // sepolia
                                    decimals: 6),
                        .Matic: (mainnet: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
                                 testnet: nil, // amoy
                                 decimals: 6)],
            
                .weth: [.Ethereum: (mainnet: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
                                    testnet: "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9", // sepolia
                                    decimals: 18),
                        .Matic: (mainnet: "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
                                 testnet: nil, // amoy
                                 decimals: 18)],
        ]
        
        static var supportedTokensUrl: String {
            "https://raw.githubusercontent.com/unstoppabledomains/unstoppable-ios-app/main/unstoppable-ios-app/domains-manager-ios/SupportingFiles/Data/supported-tokens.json"
        }
        
        
        static func getContractArray() async throws -> [CryptoSender.SupportedToken :
                                                            [BlockchainType : (mainnet: String,
                                                                                                                 testnet: String?,
                                                                                                                 decimals: UInt8)]] {
            if let data = _contracts { return data }
            
            let request = try APIRequest(urlString: supportedTokensUrl,
                                         method: .get)
            let responseData = try? await NetworkService().makeAPIRequest(request)
            
            let dataString = """
{
    "USDT" :  { "Ethereum" :   { "mainnet" : "0xdAC17F958D2ee523a2206206994597C13D831ec7",
                                "testnet": "0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0",
                                "decimals": 6 },
                "Polygon" :       { "mainnet" : "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
                                "testnet": null,
                                "decimals": 6 } },

    "BNB" :  { "Ethereum" :    { "mainnet" : "0xB8c77482e45F1F44dE1745F52C74426C631bDD52",
                                "testnet": null,
                                "decimals": 18 },
                "Polygon" :       { "mainnet" : "0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3",
                                "testnet": null,
                                "decimals": 18 } },

    "USDC" :  { "Ethereum" :   { "mainnet" : "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
                                "testnet": "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238",
                                "decimals": 6 },
                "Polygon" :       { "mainnet" : "0x3c499c542cEF5E3811e1192ce70d8C3d5C3359",
                                "testnet": null,
                                "decimals": 6 } },

    "WETH" :  { "Ethereum" :   { "mainnet" : "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
                                "testnet": "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9",
                                "decimals": 18 },
                "Polygon" :       { "mainnet" : "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
                                "testnet": null,
                                "decimals": 18 } }
}
"""
            
            var res: [CryptoSender.SupportedToken :
                        [BlockchainType : (mainnet: String,
                                           testnet: String?,
                                           decimals: UInt8)]] = [:]

            
            let jsonReg = try! JSONSerialization.jsonObject(with: dataString.data(using: .utf8)!) as! [String: [String: [String: Any]]]

            for entry in jsonReg {
                let key = try SupportedToken(tokenSymbol: entry.key)
                let blockchainTypeData = entry.value
                
                var entries: [BlockchainType : (mainnet: String,
                                                testnet: String?,
                                                decimals: UInt8)] = [:]
                for chain in blockchainTypeData {
                    guard let blockchainType = BlockchainType.blockchainType(fullName: chain.key) else {
                        throw Error.invalidChainSymbol
                    }
                    guard let mainnet: String = chain.value["mainnet"] as? String,
                          let decimals: UInt8 = chain.value["decimals"] as? UInt8 else {
                        throw Error.invalidAddresses
                    }
                    let testtet: String? = chain.value["testnet"] as? String
                    let data = (mainnet: mainnet, testnet: testtet, decimals: decimals)
                    entries[blockchainType] = data
                }
                res[key] = entries
            }
            return res
        }
        
        static private var _contracts: [CryptoSender.SupportedToken :
                                        [BlockchainType : (mainnet: String,
                                                           testnet: String?,
                                                           decimals: UInt8)]]?
        
        static func getSupportedToken(by symbol: String) -> Self? {
            CryptoSender.SupportedToken(rawValue: symbol.uppercased())
        }
        
        func getContractAddress(for chainSpec: ChainSpec) throws -> HexAddress {
            guard let addresses = Self.contractArray[self]?[chainSpec.chain.identifyBlockchainType()] else {
                throw CryptoSender.Error.tokenNotSupportedOnChain
            }
            guard let contract =  chainSpec.chain.identifyEnvironment() == .mainnet ? addresses.mainnet : addresses.testnet else {
                throw CryptoSender.Error.tokenNotSupportedOnChain
            }
            return  contract
        }
        
        func getContractDecimals(for chainType: BlockchainType) throws -> UInt8 {
            guard let decimals = Self.contractArray[self]?[chainType]?.decimals else {
                throw CryptoSender.Error.decimalsNotIdentified
            }
            return decimals
        }
    }
}
