//
//  SendCryptoAsset.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import Foundation

enum SendCryptoAsset { }

extension SendCryptoAsset {
    struct InitialData: Identifiable {
        
        var id: String { sourceWallet.id }
        
        let sourceWallet: WalletEntity
    }
}
