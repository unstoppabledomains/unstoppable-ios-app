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

struct CryptoSpec {
    let token: String
    let amount: Double
}


struct NativeCryptoSender: CryptoSenderProtocol {
    enum Error: Swift.Error {
        case sendingNotSupported
    }

    static let defaultSendTxGasPrice: BigUInt = 21_000
    static let ethTicker = "crypto.ETH.address"
    static let maticTicker = "crypto.MATIC.version.MATIC.address"
    
    let wallet: UDWallet
    
    init(wallet: UDWallet) {
        self.wallet = wallet
    }
    
    func sendCrypto(crypto: CryptoSpec,
                    chain: ChainSpec,
                    toAddress: HexAddress) async throws -> String {
        
        guard canSendCrypto(token: crypto.token, chain: chain.blockchainType) else {
            throw Error.sendingNotSupported
        }

        let chainId = chain.blockchainType.supportedChainId(env: chain.env)
        let tx = try await createNativeSendTransaction(crypto: crypto,
                                                       fromAddress: self.wallet.address,
                                                       toAddress: toAddress,
                                                       chainId: chainId)
        let hash = try await JRPC_Client.instance.sendTx(transaction: tx, udWallet: self.wallet, chainIdInt: chainId)
        return hash
    }
    
    private func createNativeSendTransaction(crypto: CryptoSpec,
                                             fromAddress: HexAddress,
                                             toAddress: HexAddress,
                                             chainId: Int) async throws -> EthereumTransaction {
        let nonce: EthereumQuantity = try await JRPC_Client.instance.fetchNonce(address: fromAddress,
                                                                                chainId: chainId)
        let gasPrice = try await JRPC_Client.instance.fetchGasPrice(chainId: chainId)
        let sender = EthereumAddress(hexString: fromAddress)
        let receiver = EthereumAddress(hexString: toAddress)
        
        let amount = BigUInt ( 1_000_000_000 * crypto.amount )
        
        var transaction = EthereumTransaction(nonce: nonce,
                                              gasPrice: gasPrice,
                                              gas: try EthereumQuantity(Self.defaultSendTxGasPrice),
                                              from: sender,
                                              to: receiver,
                                              value: try EthereumQuantity(amount.gwei)
        )
        
        if let gasEstimate = try? await JRPC_Client.instance.fetchGasLimit(transaction: transaction, chainId: chainId) {
            transaction.gas = gasEstimate
        }
        return transaction
    }
        
    func canSendCrypto(token: String, chain: BlockchainType) -> Bool {
        // only native tokens supported
        return (token == Self.ethTicker && chain == .Ethereum) ||
        (token == Self.maticTicker && chain == .Matic)
    }
}
