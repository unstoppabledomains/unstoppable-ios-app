//
//  UniversalCryptoSenderProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.05.2024.
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
    
    func getToken() throws -> CryptoSender.SupportedToken {
        guard let token = CryptoSender.SupportedToken.getSupportedToken(by: self.symbol) else {
            throw CryptoSender.Error.sendingNotSupported
        }
        return token
    }
    
    func getChain() throws -> ChainSpec {
        guard let chainType = BlockchainType.blockchainType(chainShortCode: self.chain) else {
            throw CryptoSender.Error.sendingNotSupported
        }
        let chain = ChainSpec(blockchainType: chainType, env: self.env)
        return chain
    }
    
}

struct CryptoSenderDataToSend {
    let chainDesc: CryptoSenderChainDescription
    let amount: Double
    let txSpeed: CryptoSendingSpec.TxSpeed
    let toAddress: HexAddress
    
    func getToken() throws -> CryptoSender.SupportedToken {
        try self.chainDesc.getToken()
    }
    
    func getChain() throws -> ChainSpec {
        try self.chainDesc.getChain()
    }
}
