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
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .onAppear {
                        viewModel.willDisplayTransaction(tx)
                    }
            }
            HomeExploreSeparatorView()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(.init(horizontal: 16, vertical: 0))
        } header:  {
            HStack {
                Text(DateFormattingService.shared.formatWalletActivityDate(groupedTxs.date))
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
                Spacer()
            }
            .listRowBackground(Color.clear)
            .background(Color.clear)
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
    
    func onSpeedUpTxSelected (_ tx: WalletTransactionDisplayInfo) async throws {
        let chain = CryptoSenderChainDescription(symbol: tx.symbol,
                                                 chain: "ETH",
                                                 env: .mainnet) //TODO: make particular
        let data: CryptoSenderDataToSend = CryptoSenderDataToSend(chainDesc: chain,
                                                                  amount: tx.value,
                                                                  txSpeed: .normal,
                                                                  toAddress: "")
        //try await CryptoSender(wallet: <#T##UDWallet#>).sendCrypto(dataToSend: <#T##CryptoSenderDataToSend#>)
    }
    
    func onCancelTxSelected (_ tx: WalletTransactionDisplayInfo) {
        
    }
}

#Preview {
    HomeActivityTransactionsSectionView(groupedTxs: HomeActivity.GroupedTransactions(date: Date(), txs: []))
}
