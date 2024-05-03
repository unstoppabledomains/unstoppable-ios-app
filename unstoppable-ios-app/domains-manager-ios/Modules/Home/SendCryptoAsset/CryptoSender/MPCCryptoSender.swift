//
//  MPCCryptoSender.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.05.2024.
//

import Foundation

struct MPCCryptoSender: UniversalCryptoSenderProtocol {
    
    let mpcMetadata: MPCWalletMetadata
    let wallet: UDWallet // TODO: - Remove when MPC wallet capable of handling gas fee
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
        let toAddress = dataToSend.toAddress
        try await mpcWalletsService.transferAssets(dataToSend.amount,
                                                   symbol: dataToSend.chainDesc.symbol,
                                                   chain: dataToSend.chainDesc.chain,
                                                   destinationAddress: toAddress,
                                                   by: mpcMetadata)
        return "" // TODO: - Get tx id
    }
    
    func computeGasFeeFor(dataToSend: CryptoSenderDataToSend) async throws -> EVMCoinAmount {
        // TODO: - Remove when MPC wallet capable of handling gas fee
        try await UDCryptoSender(wallet: wallet).computeGasFeeFor(dataToSend: dataToSend)
    }
    
    func fetchGasPrices(chainDesc: CryptoSenderChainDescription) async throws -> EstimatedGasPrices {
        // TODO: - Remove when MPC wallet capable of handling gas fee
        try await UDCryptoSender(wallet: wallet).fetchGasPrices(chainDesc: chainDesc)
    }
}
