//
//  CryptoSenderProtocol.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.03.2024.
//

import Foundation

protocol CryptoSenderProtocol {
    
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
    func sendCrypto(token: String, amount: Double, address: HexAddress, chain: BlockchainType) async throws -> String
}




extension CryptoSenderProtocol {
    private func _sendCrypto(token: String, amount: Double, address: HexAddress, chain: BlockchainType) async throws {
        // create the TX
        
        // send TX to the chain
        
        // store TX in the storage
    }
    
    private func createTX() {
        // TODO:
    }
    
    private func sendTX() {
        // TODO:
    }
}

// ==========================


class DemoCryptoSender: CryptoSenderProtocol {
    static let instance: DemoCryptoSender = DemoCryptoSender()
    private init() {}
    
    @discardableResult
    func sendCrypto(token: String, amount: Double, address: HexAddress, chain: BlockchainType) -> String {
        // TODO:
        return "0x"
    }
    
    func canSendCrypto(token: String, chain: BlockchainType) -> Bool {
        return false
    }
}
