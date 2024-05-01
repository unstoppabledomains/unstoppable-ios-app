//
//  CryptoSender.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.03.2024.
//

import Foundation

protocol UniversalCryptoSenderProtocol {
    func canSendCrypto(chainDesc: CryptoSenderChainDescription) -> Bool
    func sendCrypto(dataToSend: CryptoSenderDataToSend) async throws -> String
    func computeGasFeeFor(dataToSend: CryptoSenderDataToSend) async throws -> EVMCoinAmount
    func fetchGasPrices(chainDesc: CryptoSenderChainDescription) async throws -> EstimatedGasPrices
}

struct CryptoSenderChainDescription {
    let symbol: String
    let chain: String
    let env: UnsConfigManager.BlockchainEnvironment
}

struct CryptoSenderDataToSend {
    let chainDesc: CryptoSenderChainDescription
    let amount: Double
    let txSpeed: CryptoSendingSpec.TxSpeed
    let toAddress: HexAddress
}

struct CryptoSender: UniversalCryptoSenderProtocol {
    let wallet: UDWallet
    let mpcWalletsService: MPCWalletsServiceProtocol
    
    func canSendCrypto(chainDesc: CryptoSenderChainDescription) -> Bool {
        switch wallet.type {
        case .mpc:
            guard let mpcMetadata = wallet.mpcMetadata else { return false }
            
            return mpcWalletsService.canTransferAssets(symbol: chainDesc.symbol,
                                                       chain: chainDesc.chain,
                                                       by: mpcMetadata)
        default:
            guard let supportedToken = try? getSupportedTokenFor(symbol: chainDesc.symbol),
                  let chain = try? nativeChainSpecFor(chainDesc: chainDesc) else { return false }
            
            return NativeCoinCryptoSender(wallet: wallet).canSendCrypto(token: supportedToken, chain: chain) || TokenCryptoSender(wallet: wallet).canSendCrypto(token: supportedToken, chain: chain)
        }
    }
    
    private func nativeChainSpecFor(chainDesc: CryptoSenderChainDescription) throws -> ChainSpec {
        guard let chainType = BlockchainType(rawValue: chainDesc.chain) else {throw CryptoSender.Error.sendingNotSupported }
        let chain = ChainSpec(blockchainType: chainType,
                              env: chainDesc.env)
        return chain
    }

    func sendCrypto(dataToSend: CryptoSenderDataToSend) async throws -> String {
        let toAddress = dataToSend.toAddress
        switch wallet.type {
        case .mpc:
            let mpcMetadata = try wallet.extractMPCMetadata()
            
            try await mpcWalletsService.transferAssets(dataToSend.amount,
                                                       symbol: dataToSend.chainDesc.symbol,
                                                       chain: dataToSend.chainDesc.chain,
                                                       destinationAddress: toAddress,
                                                       by: mpcMetadata)
            return "" // TODO: - Get tx id
        default:
            guard let token = try? getSupportedTokenFor(symbol: dataToSend.chainDesc.symbol),
                  let chain = try? nativeChainSpecFor(chainDesc: dataToSend.chainDesc) else { throw CryptoSender.Error.sendingNotSupported }
            let crypto = try CryptoSendingSpec(token: token, units: dataToSend.amount, speed: dataToSend.txSpeed)
            
            let cryptoSender: CryptoSenderProtocol = NativeCoinCryptoSender(wallet: wallet)
            if cryptoSender.canSendCrypto(token: token, chain: chain) {
                return try await cryptoSender.sendCrypto(crypto: crypto, chain: chain, toAddress: toAddress)
            }
            
            let cryptoSender2: CryptoSenderProtocol = TokenCryptoSender(wallet: wallet)
            if cryptoSender2.canSendCrypto(token: token, chain: chain) {
                return try await cryptoSender2.sendCrypto(crypto: crypto, chain: chain, toAddress: toAddress)
            }
            throw CryptoSender.Error.sendingNotSupported
        }
    }
    
    func computeGasFeeFor(dataToSend: CryptoSenderDataToSend) async throws -> EVMCoinAmount {
        let toAddress = dataToSend.toAddress
        // TODO: - Get for mpc
        
        guard let token = try? getSupportedTokenFor(symbol: dataToSend.chainDesc.symbol),
              let chain = try? nativeChainSpecFor(chainDesc: dataToSend.chainDesc) else { throw CryptoSender.Error.sendingNotSupported }
        let crypto = try CryptoSendingSpec(token: token, units: dataToSend.amount, speed: dataToSend.txSpeed)

        let cryptoSender: CryptoSenderProtocol = NativeCoinCryptoSender(wallet: wallet)
        if cryptoSender.canSendCrypto(token: token, chain: chain) {
            return try await cryptoSender.computeGasFeeFrom(maxCrypto: crypto, on: chain, toAddress: toAddress)
        }
        
        let cryptoSender2: CryptoSenderProtocol = TokenCryptoSender(wallet: wallet)
        if cryptoSender2.canSendCrypto(token: token, chain: chain) {
            return try await cryptoSender2.computeGasFeeFrom(maxCrypto: crypto, on: chain, toAddress: toAddress)
        }
        throw CryptoSender.Error.sendingNotSupported
    }
    
    func fetchGasPrices(chainDesc: CryptoSenderChainDescription) async throws -> EstimatedGasPrices {
        let chain = try nativeChainSpecFor(chainDesc: chainDesc)
        let cryptoSender: CryptoSenderProtocol = NativeCoinCryptoSender(wallet: wallet)
        return try await cryptoSender.fetchGasPrices(on: chain)
    }
    
    private func getSupportedTokenFor(symbol: String) throws -> CryptoSender.SupportedToken {
        guard let token = CryptoSender.SupportedToken(rawValue: symbol.uppercased()) else {
            throw CryptoSender.Error.sendingNotSupported
        }
        return token
    }
    
}
