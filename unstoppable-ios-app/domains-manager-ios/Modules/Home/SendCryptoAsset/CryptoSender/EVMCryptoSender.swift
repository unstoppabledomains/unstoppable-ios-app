//
//  EVMCryptoSender.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.04.2024.
//

import Foundation
import Boilertalk_Web3
import BigInt
import Web3ContractABI
import Web3PromiseKit

typealias UDBigUInt = BigUInt

protocol EVMCryptoSender: CryptoSenderProtocol {
    var wallet: UDWallet { get }
    var defaultSendTxGasPrice: BigUInt { get }
    
    func createSendTransaction(crypto: CryptoSendingSpec,
                               fromAddress: HexAddress,
                               toAddress: HexAddress,
                               chain: ChainSpec) async throws -> EthereumTransaction
}

extension EVMCryptoSender {
    
    func sendCrypto(crypto: CryptoSendingSpec,
                    chain: ChainSpec,
                    toAddress: HexAddress) async throws -> String {
        guard canSendCrypto(token: crypto.token, chain: chain) else {
            throw CryptoSender.Error.sendingNotSupported
        }
        
        let tx = try await createSendTransaction(crypto: crypto,
                                                       fromAddress: self.wallet.address,
                                                       toAddress: toAddress,
                                                       chain: chain)
        switch wallet.type {
        case .externalLinked:
            let response = try await wallet.sendViaWalletConnectTransaction(tx: tx, chainId: chain.id)
            return response
        default:
            let hash = try await JRPC_Client.instance.sendTx(transaction: tx, udWallet: self.wallet, chainIdInt: chain.id)
            return hash
        }
    }
    
    func computeGasFeeFrom(maxCrypto: CryptoSendingSpec,
                           on chain: ChainSpec,
                           toAddress: HexAddress) async throws -> EVMCoinAmount {
        
        guard canSendCrypto(token: maxCrypto.token, chain: chain) else {
            throw CryptoSender.Error.sendingNotSupported
        }
        
        let transaction = try await createSendTransaction(crypto: maxCrypto,
                                                                fromAddress: self.wallet.address,
                                                                toAddress: toAddress,
                                                                chain: chain)
        
        guard let gasPriceWei = transaction.gasPrice?.quantity else {
            throw CryptoSender.Error.failedFetchGasPrice
        }
        let gasPrice = EVMCoinAmount(wei: gasPriceWei)
        
        let gas = transaction.gas?.quantity ?? defaultSendTxGasPrice
        let gasFee = EVMCoinAmount(gwei: gasPrice.gwei * Double(gas))
        return  gasFee
    }

    func fetchGasPrices(on chain: ChainSpec) async throws -> EstimatedGasPrices {
        try await fetchGasPrices(chainId: chain.id)
    }

    func fetchGasPrice(chainId: Int, for speed: CryptoSendingSpec.TxSpeed) async throws -> EVMCoinAmount {
        let prices: EstimatedGasPrices = try await fetchGasPrices(chainId: chainId)
        return prices.getPriceForSpeed(speed)
    }
    
    private func fetchGasPrices(chainId: Int) async throws -> EstimatedGasPrices {
        // here routes to Status or Infura source
        
        let prices: EstimatedGasPrices
        do {
            prices = try await NetworkService().fetchInfuraGasPrices(chainId: chainId)
        } catch {
            try await Task.sleep(nanoseconds: 500_000_000)
            return try await NetworkService().fetchInfuraGasPrices(chainId: chainId)
        }
        return prices
    }
}

struct NativeCoinCryptoSender: CryptoSenderProtocol, EVMCryptoSender {
    let defaultSendTxGasPrice: BigUInt = 21_000
    let wallet: UDWallet
    
    func canSendCrypto(token: CryptoSender.SupportedToken, chain: ChainSpec) -> Bool {
        // only native tokens supported
        return (token == CryptoSender.SupportedToken.eth && chain.blockchainType == .Ethereum) ||
        (token == CryptoSender.SupportedToken.matic && chain.blockchainType == .Matic)
    }
    
    internal func createSendTransaction(crypto: CryptoSendingSpec,
                                             fromAddress: HexAddress,
                                             toAddress: HexAddress,
                                             chain: ChainSpec) async throws -> EthereumTransaction {
        let nonce: EthereumQuantity = try await JRPC_Client.instance.fetchNonce(address: fromAddress,
                                                                                chainId: chain.id)
        let speedBasedGasPrice = try await fetchGasPrice(chainId: chain.id, for: crypto.speed)
        
        let sender = EthereumAddress(hexString: fromAddress)
        let receiver = EthereumAddress(hexString: toAddress)
        
        var transaction = EthereumTransaction(nonce: nonce,
                                              gasPrice: try EthereumQuantity(speedBasedGasPrice.wei),
                                              gas: try EthereumQuantity(defaultSendTxGasPrice),
                                              from: sender,
                                              to: receiver,
                                              value: try EthereumQuantity(crypto.amount.getOnChainCountable())
                                              )
        
        if let gasEstimate = try? await JRPC_Client.instance.fetchGasLimit(transaction: transaction, chainId: chain.id) {
            transaction.gas = gasEstimate
        }
        return transaction
    }
}

struct TokenCryptoSender: CryptoSenderProtocol, EVMCryptoSender {
    let defaultSendTxGasPrice: BigUInt = 100_000
    
    let wallet: UDWallet
    
    func canSendCrypto(token: CryptoSender.SupportedToken, chain: ChainSpec) -> Bool {
        return (try? token.getContractAddress(for: chain)) != nil
    }
    
    internal func createSendTransaction(crypto: CryptoSendingSpec,
                                              fromAddress: HexAddress,
                                              toAddress: HexAddress,
                                              chain: ChainSpec) async throws -> EthereumTransaction {
        let nonce: EthereumQuantity = try await JRPC_Client.instance.fetchNonce(address: fromAddress,
                                                                                chainId: chain.id)
        let speedBasedGasPrice = try await fetchGasPrice(chainId: chain.id, for: crypto.speed)
        
        guard let sender = try? EthereumAddress(hex: fromAddress, eip55: false),
              let receiver = try? EthereumAddress(hex: toAddress, eip55: false) else {
            throw CryptoSender.Error.invalidAddresses
        }

        let web3 = try JRPC_Client.instance.getWeb3(chainIdInt: chain.id)
        let tokenContractAddress = try crypto.token.getContractAddress(for: chain)
        
        guard let contractAddress = try? EthereumAddress(hex: tokenContractAddress, eip55: false) else {
            throw CryptoSender.Error.invalidAddresses
        }
        
        let erc20Contract = web3.eth.Contract(type: GenericERC20Contract.self,
                                              address: contractAddress)

        guard let transactionCreated = erc20Contract
            .transfer(to: receiver, value: crypto.amount.getOnChainCountable())
            .createTransaction(nonce: nonce,
                               from: sender,
                               value: 0, // zero native tokens transferred
                               gas: try EthereumQuantity(defaultSendTxGasPrice),
                               gasPrice:  try EthereumQuantity(speedBasedGasPrice.wei)) else {
            throw CryptoSender.Error.failedCreateSendTransaction
        }
        
        var transaction = transactionCreated
        if let gasEstimate = try? await JRPC_Client.instance.fetchGasLimit(transaction: transaction, chainId: chain.id) {
            transaction.gas = gasEstimate
        }
        return transaction
    }
}
