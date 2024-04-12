//
//  CryptoSender.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.03.2024.
//

import Foundation
import Boilertalk_Web3
import BigInt

typealias UDBigUInt = BigUInt

struct CryptoSender: CryptoSenderProtocol {
  
    let wallet: UDWallet
    
    func canSendCrypto(token: CryptoSender.SupportedToken, chainType: BlockchainType) -> Bool {
        // only native tokens supported for Ethereum and Polygon
        return NativeCryptoSender(wallet: wallet).canSendCrypto(token: token, chainType: chainType)
    }

    func sendCrypto(crypto: CryptoSendingSpec, chain: ChainSpec, toAddress: HexAddress) async throws -> String {
        let cryptoSender: CryptoSenderProtocol = NativeCryptoSender(wallet: wallet)
        return try await cryptoSender.sendCrypto(crypto: crypto, chain: chain, toAddress: toAddress)

    }
    
    func computeGasFeeFrom(maxCrypto: CryptoSendingSpec, on chain: ChainSpec, toAddress: HexAddress) async throws -> EVMTokenAmount {
        let cryptoSender: CryptoSenderProtocol = NativeCryptoSender(wallet: wallet)
        return try await cryptoSender.computeGasFeeFrom(maxCrypto: maxCrypto,
                                                        on: chain,
                                                        toAddress: toAddress)
    }
    
    func fetchGasPrices(on chain: ChainSpec) async throws -> EstimatedGasPrices {
        let cryptoSender: CryptoSenderProtocol = NativeCryptoSender(wallet: wallet)
        return try await cryptoSender.fetchGasPrices(on: chain)
    }
}

struct NativeCryptoSender: CryptoSenderProtocol {
    static let defaultSendTxGasPrice: BigUInt = 21_000
    
    let wallet: UDWallet
    
    func canSendCrypto(token: CryptoSender.SupportedToken, chainType: BlockchainType) -> Bool {
        // only native tokens supported
        return (token == CryptoSender.SupportedToken.eth && chainType == .Ethereum) ||
        (token == CryptoSender.SupportedToken.matic && chainType == .Matic)
    }
    
    func sendCrypto(crypto: CryptoSendingSpec,
                    chain: ChainSpec,
                    toAddress: HexAddress) async throws -> String {
        guard canSendCrypto(token: crypto.token, chainType: chain.blockchainType) else {
            throw CryptoSender.Error.sendingNotSupported
        }
        
        let tx = try await createNativeSendTransaction(crypto: crypto,
                                                       fromAddress: self.wallet.address,
                                                       toAddress: toAddress,
                                                       chainId: chain.id)
        
        switch wallet.walletType {
        case .externalLinked:
            let response = try await wallet.signViaWalletConnectTransaction(tx: tx, chainId: chain.id)
            return response
            
        case .mpc: print("sign with mpc")
                return "" // TODO: mpc
            
        default:  // locally verified wallet
            let hash = try await JRPC_Client.instance.sendTx(transaction: tx,
                                                             udWallet: self.wallet,
                                                             chainIdInt: chain.id)
            return hash
        }
    }
        
    func computeGasFeeFrom(maxCrypto: CryptoSendingSpec,
                           on chain: ChainSpec,
                           toAddress: HexAddress) async throws -> EVMTokenAmount {
        
        guard canSendCrypto(token: maxCrypto.token, chainType: chain.blockchainType) else {
            throw CryptoSender.Error.sendingNotSupported
        }
        
        let transaction = try await createNativeSendTransaction(crypto: maxCrypto,
                                                                fromAddress: self.wallet.address,
                                                                toAddress: toAddress,
                                                                chainId: chain.id)
        
        guard let gasPriceWei = transaction.gasPrice?.quantity else {
            throw CryptoSender.Error.failedFetchGasPrice
        }
        let gasPrice = EVMTokenAmount(wei: gasPriceWei)

        let gas = transaction.gas?.quantity ?? Self.defaultSendTxGasPrice
        let gasFee = EVMTokenAmount(gwei: gasPrice.gwei * Double(gas))
        return  gasFee
    }
    
    func fetchGasPrices(on chain: ChainSpec) async throws -> EstimatedGasPrices {
        try await fetchGasPrices(chainId: chain.id)
    }
        
    // Private methods
    
    private func createNativeSendTransaction(crypto: CryptoSendingSpec,
                                             fromAddress: HexAddress,
                                             toAddress: HexAddress,
                                             chainId: Int) async throws -> EthereumTransaction {
        let nonce: EthereumQuantity = try await JRPC_Client.instance.fetchNonce(address: fromAddress,
                                                                                chainId: chainId)
        let speedBasedGasPrice = try await fetchGasPrice(chainId: chainId, for: crypto.speed)
        
        let sender = EthereumAddress(hexString: fromAddress)
        let receiver = EthereumAddress(hexString: toAddress)
        
        var transaction = EthereumTransaction(nonce: nonce,
                                              gasPrice: try EthereumQuantity(speedBasedGasPrice.wei),
                                              gas: try EthereumQuantity(Self.defaultSendTxGasPrice),
                                              from: sender,
                                              to: receiver,
                                              value: try EthereumQuantity(crypto.amount.wei)
                                              )
        
        if let gasEstimate = try? await JRPC_Client.instance.fetchGasLimit(transaction: transaction, chainId: chainId) {
            transaction.gas = gasEstimate
        }
        return transaction
    }
    
    private func fetchGasPrice(chainId: Int, for speed: CryptoSendingSpec.TxSpeed) async throws -> EVMTokenAmount {
        let prices: EstimatedGasPrices = try await fetchGasPrices(chainId: chainId)
        return prices.getPriceForSpeed(speed)
    }
    
    private func fetchGasPrices(chainId: Int) async throws -> EstimatedGasPrices {
        // here routes to Status or Infura source
        try await NetworkService().fetchInfuraGasPrices(chainId: chainId)
    }
}
