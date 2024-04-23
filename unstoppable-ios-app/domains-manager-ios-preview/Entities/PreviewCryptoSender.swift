//
//  PreviewCryptoSender.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.04.2024.
//

import Foundation

typealias UDBigUInt = Int

struct CryptoSender: CryptoSenderProtocol {
  
    let wallet: UDWallet
    
    func canSendCrypto(token: CryptoSender.SupportedToken, chain: ChainSpec) -> Bool {
        true
    }
    
    func sendCrypto(crypto: CryptoSendingSpec, chain: ChainSpec, toAddress: HexAddress) async throws -> String {
        ""
    }
    
    func computeGasFeeFrom(maxCrypto: CryptoSendingSpec, on chain: ChainSpec, toAddress: HexAddress) async throws -> EVMCoinAmount {
        .init(wei: 12300)
    }
    
    func fetchGasPrices(on chain: ChainSpec) async throws -> EstimatedGasPrices {
        .init(normal: .init(gwei: 123), fast: .init(gwei: 432), urgent: .init(gwei: 742))
    }
}
