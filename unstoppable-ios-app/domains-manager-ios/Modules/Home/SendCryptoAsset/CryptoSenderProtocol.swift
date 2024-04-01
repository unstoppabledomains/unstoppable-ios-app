//
//  CryptoSenderProtocol.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.03.2024.
//

import Foundation
import BigInt

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


protocol CryptoSenderProtocol {
    init(wallet: UDWallet)
    
    /// Indicates if Sender supports sending of a token on the chain
    /// - Parameters:
    ///   - token: tokan name
    ///   - chain: chain
    /// - Returns: true if the sending is supported
    func canSendCrypto(token: CryptoSender.SupportedToken, chainType: BlockchainType) -> Bool
    
    /// Create TX, send it to the chain and store it to the storage as 'pending'.
    /// Method fails if sending TX failed. Otherwise it returns TX hash
    /// - Parameters:
    ///   - amount: anount of tokens
    ///   - address: address of the receiver
    ///   - chain: chain of the transaction
    /// - Returns: TX Hash if success
    func sendCrypto(crypto: CryptoSendingSpec,
                    chain: ChainSpec,
                    toAddress: HexAddress) async throws -> String
    
    /// Calculates the amount of crypto needed to be spent as gas fee
    /// - Parameters:
    ///   - maxCrypto: max crypto available for the send transaction
    ///   - chain: chain where tx will be placed
    ///   - toAddress: recepient address of the crypto
    /// - Returns: Amount of crypto that must be deducted from maxCrypto as the gas fee in the future tx, in token units
    func computeGasFeeFrom(maxCrypto: CryptoSendingSpec,
                           on chain: ChainSpec,
                           toAddress: HexAddress) async throws -> EVMTokenAmount
    
    func fetchGasPrices(on chain: ChainSpec) async throws -> EstimatedGasPrices
}
