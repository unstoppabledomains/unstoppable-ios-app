//
//  ConfirmSendTokenDataModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.03.2024.
//

import SwiftUI

final class ConfirmSendTokenDataModel: ObservableObject {
 
    let data: SendCryptoAsset.SendTokenAssetData
    @Published var txSpeed: SendCryptoAsset.TransactionSpeed = .normal
    @Published var gasFee: Double? = nil
    @Published var gasPrices: EstimatedGasPrices? = nil

    var token: BalanceTokenUIDescription { data.token }
    var receiver: SendCryptoAsset.AssetReceiver { data.receiver }
    var amount: SendCryptoAsset.TokenAssetAmountInput { data.amount }
    var gasFeeUsd: Double? {
        if let gasFee,
           let marketUsd = data.token.marketUsd {
            return gasFee * marketUsd
        }
        return nil
    }
    
    init(data: SendCryptoAsset.SendTokenAssetData) {
        self.data = data
    }
    
    func gasGweiFor(speed: SendCryptoAsset.TransactionSpeed) -> Int? {
        guard let gasPrices else { return nil }
        
        let evmSpeed = evmTxSpeedFor(transactionSpeed: speed)
        let feeForSpeed = gasPrices.feeForSpeed(evmSpeed)

        return Int(feeForSpeed.gwei)
    }
    
    private func evmTxSpeedFor(transactionSpeed: SendCryptoAsset.TransactionSpeed) -> CryptoSendingSpec.TxSpeed {
        switch transactionSpeed {
        case .normal:
            return .normal
        case .fast:
            return .fast
        case .urgent:
            return .urgent
        }
    }
    
}
