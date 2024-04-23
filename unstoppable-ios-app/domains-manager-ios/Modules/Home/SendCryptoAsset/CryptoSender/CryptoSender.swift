//
//  CryptoSender.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.03.2024.
//

import Foundation

struct CryptoSender: CryptoSenderProtocol {
    let wallet: UDWallet
    
    func canSendCrypto(token: CryptoSender.SupportedToken, chain: ChainSpec) -> Bool {
        // only native tokens supported for Ethereum and Polygon
        return NativeCoinCryptoSender(wallet: wallet).canSendCrypto(token: token, chain: chain) || TokenCryptoSender(wallet: wallet).canSendCrypto(token: token, chain: chain)
    }

    func sendCrypto(crypto: CryptoSendingSpec, chain: ChainSpec, toAddress: HexAddress) async throws -> String {
        let cryptoSender: CryptoSenderProtocol = NativeCoinCryptoSender(wallet: wallet)
        if cryptoSender.canSendCrypto(token: crypto.token, chain: chain) {
            return try await cryptoSender.sendCrypto(crypto: crypto, chain: chain, toAddress: toAddress)
        }
        
        let cryptoSender2: CryptoSenderProtocol = TokenCryptoSender(wallet: wallet)
        if cryptoSender2.canSendCrypto(token: crypto.token, chain: chain) {
            return try await cryptoSender2.sendCrypto(crypto: crypto, chain: chain, toAddress: toAddress)
        }
        throw CryptoSender.Error.sendingNotSupported
    }
    
    func computeGasFeeFrom(maxCrypto: CryptoSendingSpec, on chain: ChainSpec, toAddress: HexAddress) async throws -> EVMCoinAmount {
        let cryptoSender: CryptoSenderProtocol = NativeCoinCryptoSender(wallet: wallet)
        if cryptoSender.canSendCrypto(token: maxCrypto.token, chain: chain) {
            return try await cryptoSender.computeGasFeeFrom(maxCrypto: maxCrypto, on: chain, toAddress: toAddress)
        }
        
        let cryptoSender2: CryptoSenderProtocol = TokenCryptoSender(wallet: wallet)
        if cryptoSender2.canSendCrypto(token: maxCrypto.token, chain: chain) {
            return try await cryptoSender2.computeGasFeeFrom(maxCrypto: maxCrypto, on: chain, toAddress: toAddress)
        }
        throw CryptoSender.Error.sendingNotSupported
    }
    
    func fetchGasPrices(on chain: ChainSpec) async throws -> EstimatedGasPrices {
        let cryptoSender: CryptoSenderProtocol = NativeCoinCryptoSender(wallet: wallet)
        return try await cryptoSender.fetchGasPrices(on: chain)
    }
}
