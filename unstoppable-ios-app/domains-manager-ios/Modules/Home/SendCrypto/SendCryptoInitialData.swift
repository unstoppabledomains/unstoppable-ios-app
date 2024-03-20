//
//  SendCryptoInitialData.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import Foundation

struct SendCryptoInitialData: Identifiable {
    
    var id: String { sourceWallet.id }
    
    let sourceWallet: WalletEntity
}
