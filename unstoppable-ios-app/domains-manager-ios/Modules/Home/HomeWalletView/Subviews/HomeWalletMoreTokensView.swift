//
//  HomeWalletMoreTokensView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletMoreTokensView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text(String.Constants.homeWalletTokensComeTitle.localized())
                .font(.currentFont(size: 14, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
            Text(String.Constants.homeWalletTokensComeSubtitle.localized())
                .font(.currentFont(size: 14))
                .foregroundStyle(Color.foregroundSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .frame(height: HomeWalletTokenRowView.height)

    }
}

#Preview {
    HomeWalletMoreTokensView()
}
