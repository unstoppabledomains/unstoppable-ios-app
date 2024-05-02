//
//  UDCryptoSender.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.05.2024.
//

import Foundation

struct UDCryptoSender: UniversalCryptoSenderProtocol {
    let wallet: UDWallet
    
    func canSendCrypto(chainDesc: CryptoSenderChainDescription) -> Bool {
        guard let supportedToken = try? getSupportedTokenFor(symbol: chainDesc.symbol),
              let chain = try? nativeChainSpecFor(chainDesc: chainDesc) else { return false }
        
        return NativeCoinCryptoSender(wallet: wallet).canSendCrypto(token: supportedToken, chain: chain) || TokenCryptoSender(wallet: wallet).canSendCrypto(token: supportedToken, chain: chain)
    }
    
    private func nativeChainSpecFor(chainDesc: CryptoSenderChainDescription) throws -> ChainSpec {
        guard let chainType = BlockchainType(rawValue: chainDesc.chain) else {throw CryptoSender.Error.sendingNotSupported }
        let chain = ChainSpec(blockchainType: chainType,
                              env: chainDesc.env)
        return chain
    }
    
    func sendCrypto(dataToSend: CryptoSenderDataToSend) async throws -> String {
        let toAddress = dataToSend.toAddress
        guard let token = try? getSupportedTokenFor(symbol: dataToSend.chainDesc.symbol),
              let chain = try? nativeChainSpecFor(chainDesc: dataToSend.chainDesc) else { throw CryptoSender.Error.sendingNotSupported }
        let crypto = try CryptoSendingSpec(token: token, units: dataToSend.amount, speed: dataToSend.txSpeed)
        
        let cryptoSender: ConcreteCryptoSenderProtocol = NativeCoinCryptoSender(wallet: wallet)
        if cryptoSender.canSendCrypto(token: token, chain: chain) {
            return try await cryptoSender.sendCrypto(crypto: crypto, chain: chain, toAddress: toAddress)
        }
        
        let cryptoSender2: ConcreteCryptoSenderProtocol = TokenCryptoSender(wallet: wallet)
        if cryptoSender2.canSendCrypto(token: token, chain: chain) {
            return try await cryptoSender2.sendCrypto(crypto: crypto, chain: chain, toAddress: toAddress)
        }
        throw CryptoSender.Error.sendingNotSupported
    }
    
    func computeGasFeeFor(dataToSend: CryptoSenderDataToSend) async throws -> EVMCoinAmount {
        let toAddress = dataToSend.toAddress
        
        guard let token = try? getSupportedTokenFor(symbol: dataToSend.chainDesc.symbol),
              let chain = try? nativeChainSpecFor(chainDesc: dataToSend.chainDesc) else { throw CryptoSender.Error.sendingNotSupported }
        let crypto = try CryptoSendingSpec(token: token, units: dataToSend.amount, speed: dataToSend.txSpeed)
        
        let cryptoSender: ConcreteCryptoSenderProtocol = NativeCoinCryptoSender(wallet: wallet)
        if cryptoSender.canSendCrypto(token: token, chain: chain) {
            return try await cryptoSender.computeGasFeeFrom(maxCrypto: crypto, on: chain, toAddress: toAddress)
        }
        
        let cryptoSender2: ConcreteCryptoSenderProtocol = TokenCryptoSender(wallet: wallet)
        if cryptoSender2.canSendCrypto(token: token, chain: chain) {
            return try await cryptoSender2.computeGasFeeFrom(maxCrypto: crypto, on: chain, toAddress: toAddress)
        }
        throw CryptoSender.Error.sendingNotSupported
    }
    
    func fetchGasPrices(chainDesc: CryptoSenderChainDescription) async throws -> EstimatedGasPrices {
        let chain = try nativeChainSpecFor(chainDesc: chainDesc)
        let cryptoSender: ConcreteCryptoSenderProtocol = NativeCoinCryptoSender(wallet: wallet)
        return try await cryptoSender.fetchGasPrices(on: chain)
    }
    
    private func getSupportedTokenFor(symbol: String) throws -> CryptoSender.SupportedToken {
        guard let token = CryptoSender.SupportedToken(rawValue: symbol.uppercased()) else {
            throw CryptoSender.Error.sendingNotSupported
        }
        return token
    }
}
