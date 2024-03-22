//
//  CryptoSender.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.03.2024.
//

import Foundation
import Boilertalk_Web3
import BigInt


struct DemoCryptoSender: CryptoSenderProtocol {
    let wallet: UDWallet
    
    init(wallet: UDWallet) {
        self.wallet = wallet
    }
    
    func sendCrypto(token: String,
                    amount: Double,
                    toAddress: HexAddress,
                    chain: BlockchainType) async throws -> String {

        let chainId = chain.supportedChainId(isTestNet: true)
        
        // create TX
        let tx = try await createNativeSendTransaction(fromAddress: self.wallet.address,
                                                       toAddress: toAddress,
                                                       chainId: chainId)
        
        // send Tx
        let hash = try await JRPC_Client.instance.sendTx(transaction: tx, udWallet: self.wallet, chainIdInt: chainId)
        
        return hash
        
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

        
    }
    
    private func createNativeSendTransaction(fromAddress: HexAddress,
                                   toAddress: HexAddress,
                                   chainId: Int) async throws -> EthereumTransaction {
        let nonce: EthereumQuantity = try await JRPC_Client.instance.fetchNonce(address: fromAddress,
                                                                                chainId: chainId)
        let gasPrice = try await JRPC_Client.instance.fetchGasPrice(chainId: chainId)
        let sender = EthereumAddress(hexString: fromAddress)
        let receiver = EthereumAddress(hexString: toAddress)
        let transaction = EthereumTransaction(nonce: nonce,
                                              gasPrice: gasPrice,
                                              gas: try EthereumQuantity(21000.gwei),
                                              from: sender,
                                              to: receiver,
                                              value: try EthereumQuantity(1.gwei)
        )
        
        
        // TODO: gas limit, value
        
        
        return transaction
    }
        
    func canSendCrypto(token: String, chain: BlockchainType) -> Bool {
        return false
    }
}
