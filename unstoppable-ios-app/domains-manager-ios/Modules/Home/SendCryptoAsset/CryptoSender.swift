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
        let tx = try await createNativeSendTransaction(fromAddress: self.wallet.address,
                                                       toAddress: toAddress,
                                                       chainId: chainId)
        let hash = try await JRPC_Client.instance.sendTx(transaction: tx, udWallet: self.wallet, chainIdInt: chainId)
        return hash
    }
    
    private func createNativeSendTransaction(fromAddress: HexAddress,
                                   toAddress: HexAddress,
                                   chainId: Int) async throws -> EthereumTransaction {
        let nonce: EthereumQuantity = try await JRPC_Client.instance.fetchNonce(address: fromAddress,
                                                                                chainId: chainId)
        let gasPrice = try await JRPC_Client.instance.fetchGasPrice(chainId: chainId)
        let sender = EthereumAddress(hexString: fromAddress)
        let receiver = EthereumAddress(hexString: toAddress)
        
        var transaction = EthereumTransaction(nonce: nonce,
                                              gasPrice: gasPrice,
                                              gas: EthereumQuantity(21000),
                                              from: sender,
                                              to: receiver,
                                              value: try EthereumQuantity(222.gwei)
                                              )
        
        let gasEstimate = try await JRPC_Client.instance.fetchGasLimit(transaction: transaction, chainId: chainId)
        transaction.gas = gasEstimate
        
        
        // TODO: value
        
        
        return transaction
    }
        
    func canSendCrypto(token: String, chain: BlockchainType) -> Bool {
        return false
    }
}
