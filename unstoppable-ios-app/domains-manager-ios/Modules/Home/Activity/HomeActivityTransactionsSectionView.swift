//
//  HomeActivityTransactionsSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import SwiftUI

struct HomeActivityTransactionsSectionView: View {
    
    let groupedTxs: HomeActivity.GroupedTransactions
    
    var body: some View {
        Section {
            ForEach(groupedTxs.txs) { tx in
                WalletTransactionDisplayInfoListItemView(transaction: tx)
            }
        } header:  {
            HStack {
                Text(groupedTxs.date.formatted(.dateTime))
                    .font(.currentFont(size: 14, weight: .semibold))
                    .foregroundStyle(Color.foregroundSecondary)
                Spacer()
            }
        }
    }
}

#Preview {
    HomeActivityTransactionsSectionView(groupedTxs: HomeActivity.GroupedTransactions(date: Date(), txs: []))
}
