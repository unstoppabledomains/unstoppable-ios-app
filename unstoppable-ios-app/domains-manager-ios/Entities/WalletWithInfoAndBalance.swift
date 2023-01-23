//
//  WalletWithInfoAndBalance.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.07.2022.
//

import Foundation

struct WalletWithInfoAndBalance {
    var wallet: UDWallet
    var displayInfo: WalletDisplayInfo?
    var balance: WalletBalance
}
