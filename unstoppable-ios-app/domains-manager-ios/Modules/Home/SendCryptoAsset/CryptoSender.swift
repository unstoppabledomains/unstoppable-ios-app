//
//  CryptoSender.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.03.2024.
//

import Foundation
import Boilertalk_Web3
import BigInt

struct ChainSpec {
    let blockchainType: BlockchainType
    let env: UnsConfigManager.BlockchainEnvironment

    init(blockchainType: BlockchainType, env: UnsConfigManager.BlockchainEnvironment = .mainnet) {
        self.blockchainType = blockchainType
        self.env = env
    }
}

struct CryptoSendingSpec {
    enum TxSpeed {
        case normal, fast, urgent
    }
    
    let token: CryptoSender.SupportedToken
    let amount: Double
    let speed: TxSpeed
    
    init(token: CryptoSender.SupportedToken, amount: Double, speed: TxSpeed = .normal) {
        self.token = token
        self.amount = amount
        self.speed = speed
    }
}

struct CryptoSender: CryptoSenderProtocol {
    enum Error: Swift.Error {
        case sendingNotSupported
        case failedFetchGasPrice
    }
    
    enum SupportedToken: String {
        case eth = "ETH"
        case matic = "MATIC"
    }

    let wallet: UDWallet
    
    func canSendCrypto(token: CryptoSender.SupportedToken, chainType: BlockchainType) -> Bool {
        // only native tokens supported for Ethereum and Polygon
        return NativeCryptoSender(wallet: wallet).canSendCrypto(token: token, chainType: chainType)
    }

    func sendCrypto(crypto: CryptoSendingSpec, chain: ChainSpec, toAddress: HexAddress) async throws -> String {
        let cryptoSender: CryptoSenderProtocol = NativeCryptoSender(wallet: wallet)
        return try await cryptoSender.sendCrypto(crypto: crypto, chain: chain, toAddress: toAddress)

    }
    
    func computeGasFeeFrom(maxCrypto: CryptoSendingSpec, on chain: ChainSpec, toAddress: HexAddress) async throws -> Double {
        let cryptoSender: CryptoSenderProtocol = NativeCryptoSender(wallet: wallet)
        return try await cryptoSender.computeGasFeeFrom(maxCrypto: maxCrypto,
                                                        on: chain,
                                                        toAddress: toAddress)
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
        
        let chainId = chain.blockchainType.supportedChainId(env: chain.env)
        let tx = try await createNativeSendTransaction(crypto: crypto,
                                                       fromAddress: self.wallet.address,
                                                       toAddress: toAddress,
                                                       chainId: chainId)
        
        guard wallet.walletState != .externalLinked else {
            let response = try await wallet.signViaWalletConnectTransaction(tx: tx, chainId: chainId)
            return response
        }
        
        
        let hash = try await JRPC_Client.instance.sendTx(transaction: tx, udWallet: self.wallet, chainIdInt: chainId)
        return hash
    }
        
    func computeGasFeeFrom(maxCrypto: CryptoSendingSpec,
                           on chain: ChainSpec,
                           toAddress: HexAddress) async throws -> Double {
        
        guard canSendCrypto(token: maxCrypto.token, chainType: chain.blockchainType) else {
            throw CryptoSender.Error.sendingNotSupported
        }
        
        let chainId = chain.blockchainType.supportedChainId(env: chain.env)
        let transaction = try await createNativeSendTransaction(crypto: maxCrypto,
                                                                fromAddress: self.wallet.address,
                                                                toAddress: toAddress,
                                                                chainId: chainId)
        
        guard let gasPriceWei = transaction.gasPrice?.quantity else {
            throw CryptoSender.Error.failedFetchGasPrice
        }
        let gas = transaction.gas?.quantity ?? Self.defaultSendTxGasPrice
        
        let gasPriceGwei = (Double(gasPriceWei) / 1_000_000_000.0)
        let gasFee = gasPriceGwei * Double(gas) / 1_000_000_000.0 // in token units
        
        return  gasFee
    }
    
    // Private methods
    
    private func createNativeSendTransaction(crypto: CryptoSendingSpec,
                                             fromAddress: HexAddress,
                                             toAddress: HexAddress,
                                             chainId: Int) async throws -> EthereumTransaction {
        let nonce: EthereumQuantity = try await JRPC_Client.instance.fetchNonce(address: fromAddress,
                                                                                chainId: chainId)
        let speedBasedGasPriceGwei = try await NetworkService().fetchGasPrice(chainId: chainId,
                                                                         for: crypto.speed)
        
        let sender = EthereumAddress(hexString: fromAddress)
        let receiver = EthereumAddress(hexString: toAddress)
        let amountInGwei = BigUInt(1_000_000_000.0 * crypto.amount)
        
        var transaction = EthereumTransaction(nonce: nonce,
                                              gasPrice: try EthereumQuantity(speedBasedGasPriceGwei.gwei),
                                              gas: try EthereumQuantity(Self.defaultSendTxGasPrice),
                                              from: sender,
                                              to: receiver,
                                              value: try EthereumQuantity(amountInGwei.gwei) )
        
        if let gasEstimate = try? await JRPC_Client.instance.fetchGasLimit(transaction: transaction, chainId: chainId) {
            transaction.gas = gasEstimate
        }
        return transaction
    }
}
