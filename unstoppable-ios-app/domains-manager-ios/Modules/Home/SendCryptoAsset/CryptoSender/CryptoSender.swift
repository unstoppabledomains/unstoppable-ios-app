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

struct NativeCryptoSender: CryptoSenderProtocol, EVMCryptoSender {
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
    
    // Private methods
    
    internal func createNativeSendTransaction(crypto: CryptoSendingSpec,
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
    
    
    
    private func sendUSDT() throws {

        // Set up your Infura URL and Ethereum addresses
        let infuraUrl = "https://mainnet.infura.io/v3/YOUR_INFURA_API_KEY"
        let senderAddress = "0xYourSenderAddress"
        let privateKey = "YourPrivateKey"

        // Set up Web3 provider
        let web3 = Web3(rpcURL: "urlString")

        // Load your Ethereum address and private key
        let sender = try EthereumAddress(senderAddress)
        let privateKeyData = Data.fromHex(privateKey)

        // Load ERC20 contract
        let usdtContractAddress = "0xdac17f958d2ee523a2206206994597c13d831ec7" // USDT contract address
        
        let erc20Contract = web3.eth.Contract(type: GenericERC20Contract.self, address: try EthereumAddress(usdtContractAddress))
        
        // Send some tokens to another address (locally signing the transaction)
        let myPrivateKey = try EthereumPrivateKey(hexPrivateKey: "...")
        firstly {
            web3.eth.getTransactionCount(address: myPrivateKey.address, block: .latest)
        }.then { nonce in
//            try erc20Contract.transfer(to: EthereumAddress(hex: "0x3edB3b95DDe29580FFC04b46A68a31dD46106a4a", eip55: true), value: 100000).createTransaction(
//                nonce: nonce,
//                gasPrice: EthereumQuantity(quantity: 21.gwei),
//                maxFeePerGas: nil,
//                maxPriorityFeePerGas: nil,
//                gasLimit: 100000,
//                from: myPrivateKey.address,
//                value: 0,
//                accessList: [:],
//                transactionType: .legacy
//            )!.sign(with: myPrivateKey).promise
            
            try (erc20Contract.transfer(to: EthereumAddress(hex: "0x3edB3b95DDe29580FFC04b46A68a31dD46106a4a", eip55: true), value: 100000).createTransaction(nonce: <#T##EthereumQuantity?#>, from: <#T##EthereumAddress#>, value: <#T##EthereumQuantity?#>, gas: <#T##EthereumQuantity#>, gasPrice: <#T##EthereumQuantity?#>)?.sign(with: myPrivateKey).promise)!
        }.then { tx in
            web3.eth.sendRawTransaction(transaction: tx)
        }.done { txHash in
            print(txHash)
        }.catch { error in
            print(error)
        }

    }
}



protocol EVMCryptoSender: CryptoSenderProtocol {
    
    
    // Private methods
    
    func createNativeSendTransaction(crypto: CryptoSendingSpec,
                                             fromAddress: HexAddress,
                                             toAddress: HexAddress,
                                             chainId: Int) async throws -> EthereumTransaction
    
    
}

extension EVMCryptoSender {
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
