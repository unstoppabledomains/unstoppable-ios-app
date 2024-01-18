//
//  HomeWalletTotalBalanceView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import SwiftUI

struct HomeWalletTotalBalanceView: View {
    
    let wallet: WalletEntity

    var body: some View {
        Text(formatCartPrice(wallet.totalBalance))
            .titleText()
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
