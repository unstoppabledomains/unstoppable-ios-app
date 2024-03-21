//
//  CryptoSender.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.03.2024.
//

import Foundation
import Boilertalk_Web3
import BigInt


class DemoCryptoSender: CryptoSenderProtocol {
    static let instance: DemoCryptoSender = DemoCryptoSender()
    private init() {}

    func sendCrypto(token: String, amount: Double, address: HexAddress, chain: BlockchainType) async throws -> String {

        
        // create TX
        
        
        // send Tx
        
        
        
//        // Set up your Infura URL and Ethereum addresses
//        let infuraUrl = "https://mainnet.infura.io/v3/YOUR_INFURA_API_KEY"
//        let senderAddress = "0xYourSenderAddress"
//        let privateKey = "YourPrivateKey"
//
//        // Create a new web3 instance
//        let web3 = Web3(rpcURL: "https://mainnet.infura.io/<your_infura_id>")
//
//        // Load your Ethereum address and private key
//        let sender = try EthereumAddress(senderAddress)
//        let privateKeyData = Data.fromHex(privateKey)
//
//        // Set up transaction parameters
//        let toAddress = "0xRecipientAddress"
////        let amountToSend = Web3.Utils.parseToBigUInt("1", units: .eth)!
////        let gasPrice = Web3.Utils.parseToBigUInt("50", units: .Gwei)!
//        let gasLimit = BigUInt(21000)
//
//        // Create a transaction
//        let transaction = EthereumTransaction(
//            nonce: web3.eth.getTransactionCount(address: sender),
//            gasPrice: gasPrice,
//            gasLimit: gasLimit,
//            to: EthereumAddress(toAddress),
//            value: amountToSend,
//            data: Data()
//        )
//
//        // Sign the transaction
//        guard let signedTransaction = try? transaction.sign(with: privateKeyData, chainId: 1) else {
//            print("Failed to sign transaction")
//            return ""
//        }
//
//        // Send the transaction
//        web3.eth.sendRawTransaction(signedTransaction, withChainId: 1) { result in
//            switch result {
//            case .success(let txHash):
//                print("Transaction sent successfully. TxHash: \(txHash)")
//            case .failure(let error):
//                print("Failed to send transaction: \(error)")
//            }
//        }

        
        return ""

    }
    
    private func createTransaction(fromAddress: HexAddress,
                                   toAddress: HexAddress,
                                   chainId: Int) async throws -> EthereumTransaction {
        let nonce: EthereumQuantity = try await JRPC_Client.instance.fetchNonce(address: fromAddress,
                                                                                chainId: chainId)
        let gasPrice = try await JRPC_Client.instance.fetchGasPrice(chainId: chainId)
        let sender = EthereumAddress(hexString: fromAddress)
        let receiver = EthereumAddress(hexString: toAddress)
        var transaction = EthereumTransaction(nonce: nonce,
                                              gasPrice: gasPrice,
                                              from: sender,
                                              to: receiver,
                                              value: try EthereumQuantity(ethereumValue: 1))
        
        
        // TODO:
        
        
        return transaction
    }
    
    
    
    
    func canSendCrypto(token: String, chain: BlockchainType) -> Bool {
        return false
    }
}
