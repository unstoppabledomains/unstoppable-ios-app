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
        
        static func getSupportedToken(by symbol: String) -> Self? {
            CryptoSender.SupportedToken(rawValue: symbol.uppercased())
        }
        
        func getContractAddress(for chainSpec: ChainSpec) throws -> HexAddress {
            guard let addresses = try Self.getContractArray()[self]?[chainSpec.chain.identifyBlockchainType()] else {
                throw CryptoSender.Error.tokenNotSupportedOnChain
            }
            guard let contract =  chainSpec.chain.identifyEnvironment() == .mainnet ? addresses.mainnet : addresses.testnet else {
                throw CryptoSender.Error.tokenNotSupportedOnChain
            }
            return  contract
        }
        
        func getContractDecimals(for chainType: BlockchainType) throws -> UInt8 {
            guard let decimals = try Self.getContractArray()[self]?[chainType]?.decimals else {
                throw CryptoSender.Error.decimalsNotIdentified
            }
            return decimals
        }
        
        
        static var supportedTokensUrl: String {
            "https://raw.githubusercontent.com/unstoppabledomains/unstoppable-ios-app/main/unstoppable-ios-app/domains-manager-ios/SupportingFiles/Data/supported-tokens.json"
        }
        
        static private var _contracts: [CryptoSender.SupportedToken :
                                            [BlockchainType : (mainnet: String,
                                                               testnet: String?,
                                                               decimals: UInt8)]]?
        
        
        static func getContractArray(from data: Data? = nil) throws -> [CryptoSender.SupportedToken :
                                                                                [BlockchainType : (mainnet: String,
                                                                                                   testnet: String?,
                                                                                                   decimals: UInt8)]] {
            @Sendable func fetch() async throws -> Data {
                let request = try APIRequest(urlString: supportedTokensUrl,
                                             method: .get)
                if let responseData = try? await NetworkService().makeAPIRequest(request) {
                    return responseData
                } else {
                    return hardcodedTokensData.data(using: .utf8)!
                }
            }
            
            @Sendable func parse(data: Data) throws -> [CryptoSender.SupportedToken :
                                                [BlockchainType : (mainnet: String,
                                                                   testnet: String?,
                                                                   decimals: UInt8)]] {
                let jsonReg = try! JSONSerialization.jsonObject(with: data) as! [String: [String: [String: Any]]]
                
                var res: [CryptoSender.SupportedToken :
                            [BlockchainType : (mainnet: String,
                                               testnet: String?,
                                               decimals: UInt8)]] = [:]
                
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
            if let injectedData = data {
                return try parse(data: injectedData)
            }
            if let loadedInfo = _contracts { return loadedInfo }
            
            Task {
                let downloadedData = try await fetch()
                _contracts = try parse(data: downloadedData)
                
            }
            
            return try parse(data: hardcodedTokensData.data(using: .utf8)!)
        }
        
        
        static private var hardcodedTokensData: String {
            let bundler = Bundle.main
            let filePath = bundler.url(forResource: "supported-tokens", withExtension: "json")!
            let data = try! Data(contentsOf: filePath)
            return String(data: data, encoding: .utf8)!
        }
    }
}
