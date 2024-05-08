//
//  CryptoSender.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.03.2024.
//

import Foundation

struct CryptoSender: UniversalCryptoSenderProtocol {
    let sender: UniversalCryptoSenderProtocol
    
    init(wallet: UDWallet) throws {
        switch wallet.type {
        case .mpc:
            let mpcMetadata = try wallet.extractMPCMetadata()
            sender = MPCCryptoSender(mpcMetadata: mpcMetadata, wallet: wallet)
        default:
            sender = UDCryptoSender(wallet: wallet)
        }
    }
    
    func canSendCrypto(chainDesc: CryptoSenderChainDescription) -> Bool {
        sender.canSendCrypto(chainDesc: chainDesc)
    }
    
    func sendCrypto(dataToSend: CryptoSenderDataToSend) async throws -> String {
        try await sender.sendCrypto(dataToSend: dataToSend)
    }
    
    func computeGasFeeFor(dataToSend: CryptoSenderDataToSend) async throws -> EVMCoinAmount {
        try await sender.computeGasFeeFor(dataToSend: dataToSend)
    }
    
    func fetchGasPrices(chainDesc: CryptoSenderChainDescription) async throws -> EstimatedGasPrices {
        try await sender.fetchGasPrices(chainDesc: chainDesc)
    }
}
