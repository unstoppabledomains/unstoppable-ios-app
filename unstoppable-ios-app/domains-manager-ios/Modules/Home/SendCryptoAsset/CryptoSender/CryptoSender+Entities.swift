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

protocol ERC20TokenAmount {
    var decimals: UInt8 { get }
}

struct USDT: ERC20TokenAmount, OnChainCountable {
    var elementaryUnits: UDBigUInt
    
    init(units: Double) {
        self.elementaryUnits = UDBigUInt(units * pow(10, Double(decimals)))
    }
    
    func getOnChainCountable() -> UDBigUInt {
        elementaryUnits
    }
    
    let decimals: UInt8 = 6
    
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
    let blockchainType: BlockchainType
    let env: UnsConfigManager.BlockchainEnvironment
    
    init(blockchainType: BlockchainType, env: UnsConfigManager.BlockchainEnvironment = .mainnet) {
        self.blockchainType = blockchainType
        self.env = env
    }
    
    var id: Int {
        self.blockchainType.supportedChainId(env: self.env)
    }
}

struct CryptoSendingSpec {
    enum TxSpeed {
        case normal, fast, urgent
    }
    
    let token: CryptoSender.SupportedToken
    let amount: OnChainCountable
    let speed: TxSpeed
    
    init(token: CryptoSender.SupportedToken, amount: OnChainCountable, speed: TxSpeed = .normal) {
        self.token = token
        self.amount = amount
        self.speed = speed
    }
}

extension CryptoSender {
    enum Error: Swift.Error {
        case sendingNotSupported
        case failedFetchGasPrice
        case failedCreateSendTransaction
        case insufficientFunds
        case invalidAddresses
    }
    
    enum SupportedToken: String {
        case eth = "ETH"
        case matic = "MATIC"
        case usdt = "USDT"
    }
}
