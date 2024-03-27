//
//  HomeActivity.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

// Namespace
enum HomeActivity { }

// MARK: - Open methods
extension HomeActivity {
    struct GroupedTransactions: Hashable {
        let date: Date
        let txs: [WalletTransactionDisplayInfo]
        
        init(date: Date, txs: [WalletTransactionDisplayInfo]) {
            self.date = date
            self.txs = txs.sorted { $0.time > $1.time }
        }
        
        static func buildGroupsFrom(txs: [WalletTransactionDisplayInfo]) -> [GroupedTransactions] {
            txs.reduce(into: [Date: [WalletTransactionDisplayInfo]]()) { result, tx in
                let date = tx.time.dayStart
                result[date, default: []].append(tx)
            }
            .map { GroupedTransactions(date: $0.key, txs: $0.value) }
            .sorted { $0.date > $1.date }
        }
        
    }
}
