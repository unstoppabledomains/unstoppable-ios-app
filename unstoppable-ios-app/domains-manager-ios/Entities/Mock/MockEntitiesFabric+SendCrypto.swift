//
//  MockEntities+SendCrypto.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import UIKit

extension MockEntitiesFabric {
    @MainActor
    enum SendCrypto {
        
        static func mockViewModel() -> SendCryptoAssetViewModel {
            SendCryptoAssetViewModel(initialData: .init(sourceWallet: Wallet.mockEntities()[0]))
        }
        
        static func mockReceiver() -> SendCryptoAsset.AssetReceiver {
            .init(walletAddress: Wallet.mockEntities()[1].address,
                  regexPattern: .ETH)
        }
        
    }
}
