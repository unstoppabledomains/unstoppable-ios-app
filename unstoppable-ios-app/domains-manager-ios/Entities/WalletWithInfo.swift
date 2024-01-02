//
//  WalletWithInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.06.2022.
//

import Foundation

struct WalletWithInfo: Sendable {
    var wallet: UDWallet
    var displayInfo: WalletDisplayInfo?
    
    var address: String { wallet.address }
}
