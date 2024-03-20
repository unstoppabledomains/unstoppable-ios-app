//
//  CryptoSenderProtocol.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.03.2024.
//

import Foundation

protocol StoredSendTransactionProtocol {
    var status: TxStatusGroup { get }
}

protocol CryptoSenderProtocol {
    
    /// Indicates of Sender supports sending of a token on the chain
    /// - Parameters:
    ///   - token: tokan name
    ///   - chain: chain
    /// - Returns: true if the sending is supported
    func canSendCrypto(token: String, chain: BlockchainType) -> Bool
    
    /// Create TX, send it to the chain and store it to the storage as 'pending'
    /// - Parameters:
    ///   - amount: anount of tokens
    ///   - address: address of the receiver
    ///   - chain: chain of the transaction
    func sendCrypto(token: String, amount: Double, address: HexAddress, chain: BlockchainType)
    
    func getSendTxs() -> [StoredSendTransactionProtocol]
}

extension CryptoSenderProtocol {
    func sendCrypto(amount: Double, address: HexAddress, chain: BlockchainType) {
        // create the TX
        
        // send TX to the chain
        
        // store TX in the storage
    }
    
    private func createTX() {
        
    }
    
    private func sendTX() {
        
    }
    
    private func storeTX() {
        
    }
}

// ==========================

struct DemoSendTransaction: StoredSendTransactionProtocol {
    var status: TxStatusGroup
    let token: String
    let amount: Double
}

class DemoCryptoSender: CryptoSenderProtocol {
    func sendCrypto(token: String, amount: Double, address: HexAddress, chain: BlockchainType) {
        // TODO:
    }
    
    func canSendCrypto(token: String, chain: BlockchainType) -> Bool {
        return false
    }
    
    func getSendTxs() -> [StoredSendTransactionProtocol] {
        return [DemoSendTransaction(status: .pending,
                                    token: "crypto.LINK.address",
                                    amount: 1.0)]
    }
}
