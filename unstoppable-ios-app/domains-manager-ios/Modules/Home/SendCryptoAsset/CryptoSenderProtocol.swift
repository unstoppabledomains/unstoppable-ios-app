//
//  CryptoSenderProtocol.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.03.2024.
//

import Foundation
import BigInt

protocol CryptoSenderProtocol {
    init(wallet: UDWallet)
    
    /// Indicates if Sender supports sending of a token on the chain
    /// - Parameters:
    ///   - token: tokan name
    ///   - chain: chain
    /// - Returns: true if the sending is supported
    func canSendCrypto(token: String, chain: BlockchainType) -> Bool
    
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
    
    func computeGasFeeFrom(maxCrypto: CryptoSendingSpec,
                           on chain: ChainSpec,
                           toAddress: HexAddress) async throws -> BigUInt
}

extension CryptoSenderProtocol {
    static var defaultSendTxGasPrice: BigUInt { 21_000 }
    static var ethTicker: String { "crypto.ETH.address" }
    static var maticTicker: String { "crypto.MATIC.version.MATIC.address" }
}
