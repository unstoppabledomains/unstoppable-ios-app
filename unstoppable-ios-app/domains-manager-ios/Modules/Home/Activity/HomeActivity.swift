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
            let (todayTxs, otherTxs) = breakTxsByTodayAndOthers(txs: txs)
           
            let otherGroups = otherTxs.reduce(into: [Date: [WalletTransactionDisplayInfo]]()) { result, tx in
                let date = tx.time.monthStart
                result[date, default: []].append(tx)
            }
                .map { GroupedTransactions(date: $0.key, txs: $0.value) }
                .sorted { $0.date > $1.date }
            
            if todayTxs.isEmpty {
                return otherGroups
            }
            
            let todayGroup = GroupedTransactions(date: Date(), txs: todayTxs)

            return [todayGroup] + otherGroups
        }
        
        private static func breakTxsByTodayAndOthers(txs: [WalletTransactionDisplayInfo]) -> (today: [WalletTransactionDisplayInfo], other: [WalletTransactionDisplayInfo]) {
            var todayTxs = [WalletTransactionDisplayInfo]()
            var otherTxs = [WalletTransactionDisplayInfo]()
            
            for tx in txs {
                if tx.time.isToday {
                    todayTxs.append(tx)
                } else {
                    otherTxs.append(tx)
                }
            }
            
            return (todayTxs, otherTxs)
        }
        
    }
}

// MARK: - Filter options
extension HomeActivity {
    
    enum TransactionSubject: String, Hashable, CaseIterable, SelectionPopoverViewItem {
        case transfer
        case collectible
        case domain
        
        var selectionTitle: String { rawValue }
    }
    
    enum TransactionDestination: String, CaseIterable, UDSegmentedControlItem {
        case all
        case income
        case outcome
        
        var title: String {
            switch self {
            case .all:
                String.Constants.all.localized()
            case .income:
                String.Constants.income.localized()
            case .outcome:
                String.Constants.outcome.localized()
            }
        }
        
        var analyticButton: Analytics.Button {
            switch self {
            case .all:
                    .all
            case .income:
                    .income
            case .outcome:
                    .outcome
            }
        }
    }

}
