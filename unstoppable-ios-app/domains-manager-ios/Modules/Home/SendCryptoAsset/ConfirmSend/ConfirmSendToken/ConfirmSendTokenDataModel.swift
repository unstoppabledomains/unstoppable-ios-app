//
//  ConfirmSendTokenDataModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.03.2024.
//

import SwiftUI

final class ConfirmSendTokenDataModel: ObservableObject, Hashable {
 
    let data: SendCryptoAsset.SendTokenAssetData
    @Published var txSpeed: SendCryptoAsset.TransactionSpeed = .normal
    @Published var gasAmount: Double? = nil

    var token: BalanceTokenUIDescription { data.token }
    var receiver: SendCryptoAsset.AssetReceiver { data.receiver }
    var amount: SendCryptoAsset.TokenAssetAmountInput { data.amount }
    var gasUsd: Double? {
        if let gasAmount,
           let marketUsd = data.token.marketUsd {
            return gasAmount * marketUsd
        }
        return nil
    }
    
    init(data: SendCryptoAsset.SendTokenAssetData) {
        self.data = data
    }
    
    static func == (lhs: ConfirmSendTokenDataModel, rhs: ConfirmSendTokenDataModel) -> Bool {
        lhs.data == rhs.data &&
        lhs.txSpeed == rhs.txSpeed &&
        lhs.gasAmount == rhs.gasAmount
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(txSpeed)
        hasher.combine(gasAmount)
    }
    
}
