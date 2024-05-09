//
//  MPCCryptoSender.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.05.2024.
//

import Foundation

struct MPCCryptoSender: UniversalCryptoSenderProtocol {
    
    let mpcMetadata: MPCWalletMetadata
    let mpcWalletsService = appContext.mpcWalletsService
    
    func canSendCrypto(chainDesc: CryptoSenderChainDescription) -> Bool {
        mpcWalletsService.canTransferAssets(symbol: chainDesc.symbol,
                                            chain: chainDesc.chain,
                                            by: mpcMetadata)
    }
    
    private func nativeChainSpecFor(chainDesc: CryptoSenderChainDescription) throws -> ChainSpec {
        guard let chainType = BlockchainType(rawValue: chainDesc.chain) else {throw CryptoSender.Error.sendingNotSupported }
        let chain = ChainSpec(blockchainType: chainType,
                              env: chainDesc.env)
        return chain
    }
    
    func sendCrypto(dataToSend: CryptoSenderDataToSend) async throws -> String {
        try await mpcWalletsService.transferAssets(dataToSend.amount,
                                                   symbol: dataToSend.chainDesc.symbol,
                                                   chain: dataToSend.chainDesc.chain,
                                                   destinationAddress: dataToSend.toAddress,
                                                   by: mpcMetadata)
    }
    
    func computeGasFeeFor(dataToSend: CryptoSenderDataToSend) async throws -> EVMCoinAmount {
        let amount = try await mpcWalletsService.fetchGasFeeFor(dataToSend.amount,
                                                                symbol: dataToSend.chainDesc.symbol,
                                                                chain: dataToSend.chainDesc.chain,
                                                                destinationAddress: dataToSend.toAddress,
                                                                by: mpcMetadata)
        
        return EVMCoinAmount(units: amount)
    }
    
    func fetchGasPrices(chainDesc: CryptoSenderChainDescription) async throws -> EstimatedGasPrices {
        .init(normal: .init(units: 0),
              fast: .init(units: 0),
              urgent: .init(units: 0))
    }
}
