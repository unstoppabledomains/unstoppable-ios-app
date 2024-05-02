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
        guard let supportedToken = try? chainDesc.getToken(),
              let chain = try? chainDesc.getChain() else { return false }
        
        return NativeCoinCryptoSender(wallet: wallet).canSendCrypto(token: supportedToken, chain: chain) || TokenCryptoSender(wallet: wallet).canSendCrypto(token: supportedToken, chain: chain)
    }
    
    
    func sendCrypto(dataToSend: CryptoSenderDataToSend) async throws -> String {
        let toAddress = dataToSend.toAddress
        let token = try dataToSend.getToken()
        let chain = try dataToSend.getChain()
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
        let token = try dataToSend.getToken()
        let chain = try dataToSend.getChain()
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
        let chain = try chainDesc.getChain()
        return try await NetworkService().fetchInfuraGasPrices(chainId: chain.id)
    }
}
