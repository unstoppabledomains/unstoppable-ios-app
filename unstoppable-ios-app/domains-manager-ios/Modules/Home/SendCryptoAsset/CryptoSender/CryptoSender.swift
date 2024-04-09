//
//  CryptoSender.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.03.2024.
//

import Foundation
import Boilertalk_Web3
import BigInt
import Web3ContractABI
import Web3PromiseKit

typealias UDBigUInt = BigUInt

struct CryptoSender: CryptoSenderProtocol {
    let wallet: UDWallet
    
    func canSendCrypto(token: CryptoSender.SupportedToken, chainType: BlockchainType) -> Bool {
        // only native tokens supported for Ethereum and Polygon
        return NativeCryptoSender(wallet: wallet).canSendCrypto(token: token, chainType: chainType) || NonNativeCryptoSender(wallet: wallet).canSendCrypto(token: token, chainType: chainType)
    }

    func sendCrypto(crypto: CryptoSendingSpec, chain: ChainSpec, toAddress: HexAddress) async throws -> String {
        let cryptoSender: CryptoSenderProtocol = NativeCryptoSender(wallet: wallet)
        if cryptoSender.canSendCrypto(token: crypto.token, chainType: chain.blockchainType) {
            return try await cryptoSender.sendCrypto(crypto: crypto, chain: chain, toAddress: toAddress)
        }
        
        let cryptoSender2: CryptoSenderProtocol = NonNativeCryptoSender(wallet: wallet)
        if cryptoSender2.canSendCrypto(token: crypto.token, chainType: chain.blockchainType) {
            return try await cryptoSender2.sendCrypto(crypto: crypto, chain: chain, toAddress: toAddress)
        }
        throw CryptoSender.Error.sendingNotSupported
    }
    
    func computeGasFeeFrom(maxCrypto: CryptoSendingSpec, on chain: ChainSpec, toAddress: HexAddress) async throws -> EVMTokenAmount {
        let cryptoSender: CryptoSenderProtocol = NativeCryptoSender(wallet: wallet)
        if cryptoSender.canSendCrypto(token: maxCrypto.token, chainType: chain.blockchainType) {
            return try await cryptoSender.computeGasFeeFrom(maxCrypto: maxCrypto, on: chain, toAddress: toAddress)
        }
        
        let cryptoSender2: CryptoSenderProtocol = NonNativeCryptoSender(wallet: wallet)
        if cryptoSender2.canSendCrypto(token: maxCrypto.token, chainType: chain.blockchainType) {
            return try await cryptoSender2.computeGasFeeFrom(maxCrypto: maxCrypto, on: chain, toAddress: toAddress)
        }
        throw CryptoSender.Error.sendingNotSupported
    }
    
    func fetchGasPrices(on chain: ChainSpec) async throws -> EstimatedGasPrices {
        let cryptoSender: CryptoSenderProtocol = NativeCryptoSender(wallet: wallet)
        return try await cryptoSender.fetchGasPrices(on: chain)
    }
}

struct NativeCryptoSender: CryptoSenderProtocol, EVMCryptoSender {
    let defaultSendTxGasPrice: BigUInt = 21_000
    let wallet: UDWallet
    
    func canSendCrypto(token: CryptoSender.SupportedToken, chainType: BlockchainType) -> Bool {
        // only native tokens supported
        return (token == CryptoSender.SupportedToken.eth && chainType == .Ethereum) ||
        (token == CryptoSender.SupportedToken.matic && chainType == .Matic)
    }
    
    internal func createSendTransaction(crypto: CryptoSendingSpec,
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
                                              gas: try EthereumQuantity(defaultSendTxGasPrice),
                                              from: sender,
                                              to: receiver,
                                              value: try EthereumQuantity(crypto.amount.wei)
                                              )
        
        if let gasEstimate = try? await JRPC_Client.instance.fetchGasLimit(transaction: transaction, chainId: chainId) {
            transaction.gas = gasEstimate
        }
        return transaction
    }
}


struct NonNativeCryptoSender: CryptoSenderProtocol, EVMCryptoSender {
    let defaultSendTxGasPrice: BigUInt = 100_000
    
    let wallet: UDWallet
    
    func canSendCrypto(token: CryptoSender.SupportedToken, chainType: BlockchainType) -> Bool {
        // only native tokens supported
        return (token == CryptoSender.SupportedToken.usdt && chainType == .Ethereum) // TODO:
    }
    
    internal func createSendTransaction(crypto: CryptoSendingSpec,
                                              fromAddress: HexAddress,
                                              toAddress: HexAddress,
                                              chainId: Int) async throws -> EthereumTransaction {
        let nonce: EthereumQuantity = try await JRPC_Client.instance.fetchNonce(address: fromAddress,
                                                                                chainId: chainId)
        let speedBasedGasPrice = try await fetchGasPrice(chainId: chainId, for: crypto.speed)
        
        guard let sender = try? EthereumAddress(hex: fromAddress, eip55: false),
              let receiver = try? EthereumAddress(hex: toAddress, eip55: false) else {
            throw CryptoSender.Error.invalidAddresses
        }
        // Load ERC20 contract
        let web3 = try JRPC_Client.instance.getWeb3(chainIdInt: chainId)
        let usdtContractAddress = "0xdac17f958d2ee523a2206206994597c13d831ec7" // USDT contract address
        guard let contractAddress = try? EthereumAddress(hex: usdtContractAddress, eip55: false) else {
            throw CryptoSender.Error.invalidAddresses
        }
        
        let erc20Contract = web3.eth.Contract(type: GenericERC20Contract.self,
                                              address: contractAddress)

        guard let transactionCreated = erc20Contract
            .transfer(to: receiver, value: crypto.amount.wei)
            .createTransaction(nonce: nonce,
                               from: sender,
                               value: 0, // zero native tokens transferred
                               gas: 100000, // TODO:
                               gasPrice:  try EthereumQuantity(speedBasedGasPrice.wei)) else {
            throw JRPC_Client.Error.failedFetchGas
        }
        
        var transaction = transactionCreated
        if let gasEstimate = try? await JRPC_Client.instance.fetchGasLimit(transaction: transaction, chainId: chainId) {
            transaction.gas = gasEstimate
        }
        return transaction
    }
}


protocol EVMCryptoSender: CryptoSenderProtocol {
    
    var wallet: UDWallet { get }
    var defaultSendTxGasPrice: BigUInt { get }
    
    func createSendTransaction(crypto: CryptoSendingSpec,
                               fromAddress: HexAddress,
                               toAddress: HexAddress,
                               chainId: Int) async throws -> EthereumTransaction
}

extension EVMCryptoSender {
    
    func sendCrypto(crypto: CryptoSendingSpec,
                    chain: ChainSpec,
                    toAddress: HexAddress) async throws -> String {
        guard canSendCrypto(token: crypto.token, chainType: chain.blockchainType) else {
            throw CryptoSender.Error.sendingNotSupported
        }
        
        let tx = try await createSendTransaction(crypto: crypto,
                                                       fromAddress: self.wallet.address,
                                                       toAddress: toAddress,
                                                       chainId: chain.id)
        
        guard wallet.walletState != .externalLinked else {
            let response = try await wallet.signViaWalletConnectTransaction(tx: tx, chainId: chain.id)
            return response
        }
        
        
        let hash = try await JRPC_Client.instance.sendTx(transaction: tx, udWallet: self.wallet, chainIdInt: chain.id)
        return hash
    }
    
    func computeGasFeeFrom(maxCrypto: CryptoSendingSpec,
                           on chain: ChainSpec,
                           toAddress: HexAddress) async throws -> EVMTokenAmount {
        
        guard canSendCrypto(token: maxCrypto.token, chainType: chain.blockchainType) else {
            throw CryptoSender.Error.sendingNotSupported
        }
        
        let transaction = try await createSendTransaction(crypto: maxCrypto,
                                                                fromAddress: self.wallet.address,
                                                                toAddress: toAddress,
                                                                chainId: chain.id)
        
        guard let gasPriceWei = transaction.gasPrice?.quantity else {
            throw CryptoSender.Error.failedFetchGasPrice
        }
        let gasPrice = EVMTokenAmount(wei: gasPriceWei)
        
        let gas = transaction.gas?.quantity ?? defaultSendTxGasPrice
        let gasFee = EVMTokenAmount(gwei: gasPrice.gwei * Double(gas))
        return  gasFee
    }

    func fetchGasPrices(on chain: ChainSpec) async throws -> EstimatedGasPrices {
        try await fetchGasPrices(chainId: chain.id)
    }

    func fetchGasPrice(chainId: Int, for speed: CryptoSendingSpec.TxSpeed) async throws -> EVMTokenAmount {
        let prices: EstimatedGasPrices = try await fetchGasPrices(chainId: chainId)
        return prices.getPriceForSpeed(speed)
    }
    
    private func fetchGasPrices(chainId: Int) async throws -> EstimatedGasPrices {
        // here routes to Status or Infura source
        try await NetworkService().fetchInfuraGasPrices(chainId: chainId)
    }
}
