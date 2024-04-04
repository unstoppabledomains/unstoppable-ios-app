//
//  WalletTransactionsResponse.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

struct WalletTransactionsResponse {
    let canLoadMore: Bool
    let txs: [SerializedWalletTransaction]
}
