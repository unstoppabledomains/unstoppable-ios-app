//
//  HomeWalletCollectiblesEmptyView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletCollectiblesEmptyView: View {
   
    let walletAddress: String
    private let ticker = "ETH"
    
    var body: some View {
        VStack(spacing: 16) {
            Image.layoutGridEmptyIcon
                .resizable()
                .renderingMode(.template)
                .squareFrame(32)
            VStack(spacing: 8) {
                Text(String.Constants.homeWalletCollectiblesEmptyTitle.localized())
                    .font(.currentFont(size: 20, weight: .bold))
                Text(String.Constants.homeWalletCollectiblesEmptySubtitle.localized())
                    .font(.currentFont(size: 14))
            }
            .multilineTextAlignment(.center)
            
            UDButtonView(text: String.Constants.copyAddress.localized(), icon: .squareBehindSquareIcon, style: .small(.raisedTertiary)) {
                CopyWalletAddressPullUpHandler.copyToClipboard(address: walletAddress,
                                                               ticker: ticker)
            }
        }
        .foregroundStyle(Color.foregroundSecondary)
        .frame(maxWidth: .infinity)
    }
    
}

#Preview {
    HomeWalletCollectiblesEmptyView(walletAddress: "")
}
