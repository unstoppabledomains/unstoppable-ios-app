//
//  CryptoSenderProtocol.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.03.2024.
//

import Foundation

protocol CryptoSenderProtocol {
    init(wallet: UDWallet)
    
    /// Indicates if Sender supports sending of a token on the chain
    /// - Parameters:
    ///   - token: tokan name
    ///   - chain: chain
    /// - Returns: true if the sending is supported
    func canSendCrypto(token: CryptoSender.SupportedToken, chain: ChainSpec) -> Bool
    
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
                           toAddress: HexAddress) async throws -> EVMCoinAmount
    
    func fetchGasPrices(on chain: ChainSpec) async throws -> EstimatedGasPrices
}
