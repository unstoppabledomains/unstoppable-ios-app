//
//  MockEntities+SendCrypto.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import UIKit

extension MockEntitiesFabric {
    enum SendCrypto {
        
        static func mockViewModel() -> SendCryptoAssetViewModel {
            SendCryptoAssetViewModel(initialData: .init(sourceWallet: Wallet.mockEntities()[0]))
        }
        
    }
}
