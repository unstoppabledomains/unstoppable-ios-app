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
struct EVMTokenAmount {
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
    
    init(wei: BigUInt) {
        self.gweiTotal = Double(wei) / Self.Billion
    }
    
    var units: Double {
        gweiTotal / Self.Billion
    }
    
    var gwei: Double {
        gweiTotal
    }
    
    var wei: BigUInt { // can only be integer and may be very big
        BigUInt(gweiTotal * Self.Billion)
    }
}

struct EstimatedGasPrices {
    let normal: EVMTokenAmount
    let fast: EVMTokenAmount
    let urgent: EVMTokenAmount
    
    func getPriceForSpeed(_ txSpeed: CryptoSendingSpec.TxSpeed) -> EVMTokenAmount {
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
    let amount: EVMTokenAmount
    let speed: TxSpeed
    
    init(token: CryptoSender.SupportedToken, amount: EVMTokenAmount, speed: TxSpeed = .normal) {
        self.token = token
        self.amount = amount
        self.speed = speed
    }
}

extension CryptoSender {
    enum Error: Swift.Error {
        case sendingNotSupported
        case failedFetchGasPrice
        case insufficientFunds
    }
    
    enum SupportedToken: String {
        case eth = "ETH"
        case matic = "MATIC"
    }
}
