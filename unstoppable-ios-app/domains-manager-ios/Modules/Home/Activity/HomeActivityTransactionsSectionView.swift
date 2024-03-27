//
//  HomeActivityTransactionsSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import SwiftUI

struct HomeActivityTransactionsSectionView: View {
    
    @EnvironmentObject var viewModel: HomeActivityViewModel
    let groupedTxs: HomeActivity.GroupedTransactions
    
    var body: some View {
        Section {
            ForEach(groupedTxs.txs) { tx in
                clickableTxRowView(tx)
                    .onAppear {
                        viewModel.willDisplayTransaction(tx)
                    }
            }
        } header:  {
            HStack {
                Text(DateFormattingService.shared.formatICloudBackUpDate(groupedTxs.date))
                    .font(.currentFont(size: 14, weight: .semibold))
                    .foregroundStyle(Color.foregroundSecondary)
                Spacer()
            }
        }
    }
}

// MARK: - Private methods
private extension HomeActivityTransactionsSectionView {
    @ViewBuilder
    func clickableTxRowView(_ tx: WalletTransactionDisplayInfo) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            if let url = tx.link {
                openLink(.direct(url: url))
            }
        } label: {
            WalletTransactionDisplayInfoListItemView(transaction: tx)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(tx.link != nil)
    }
}

#Preview {
    HomeActivityTransactionsSectionView(groupedTxs: HomeActivity.GroupedTransactions(date: Date(), txs: []))
}
