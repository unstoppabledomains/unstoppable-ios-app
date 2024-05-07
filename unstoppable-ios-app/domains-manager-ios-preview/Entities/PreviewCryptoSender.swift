//
//  PreviewCryptoSender.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.04.2024.
//

import Foundation

typealias UDBigUInt = Int

struct CryptoSender: UniversalCryptoSenderProtocol {
    
    func canSendCrypto(chainDesc: CryptoSenderChainDescription) -> Bool {
        true
    }
    
    func sendCrypto(dataToSend: CryptoSenderDataToSend) async throws -> String {
        ""
    }
    
    func computeGasFeeFor(dataToSend: CryptoSenderDataToSend) async throws -> EVMCoinAmount {
        .init(wei: 12300)
    }
    
    func fetchGasPrices(chainDesc: CryptoSenderChainDescription) async throws -> EstimatedGasPrices {
        .init(normal: .init(gwei: 123), fast: .init(gwei: 432), urgent: .init(gwei: 742))
    }
    
    let wallet: UDWallet
   
}
