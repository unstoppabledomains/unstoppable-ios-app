//
//  HomeWalletTokenRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletTokenRowView: View {
    
    static let height: CGFloat = 64
    let token: BalanceTokenUIDescription
    var secondaryColor: Color = .foregroundSecondary
    
    var body: some View {
        HStack(spacing: 16) {
            BalanceTokenIconsView(token: token)
            tokenNameWithBalanceView()
            Spacer()
            trailingTokenInfoView()
        }
        .frame(height: HomeWalletTokenRowView.height)
        .setSkeleton(.constant(token.isSkeleton),
                     animationType: .solid(.backgroundSubtle))
    }
}

// MARK: - Private methods
private extension HomeWalletTokenRowView {
    @ViewBuilder
    func tokenNameWithBalanceView() -> some View {
        VStack(alignment: .leading,
               spacing: token.isSkeleton ? 8 : 0) {
            Text(token.name)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
                .frame(height: token.isSkeleton ? 16 : 24)
                .skeletonable()
                .skeletonCornerRadius(12)
            Text(token.formattedBalanceWithSymbol)
                .font(.currentFont(size: 14, weight: .regular))
                .foregroundStyle(secondaryColor)
                .frame(height: token.isSkeleton ? 12 : 20)
                .skeletonable()
                .skeletonCornerRadius(10)
        }
    }
    
    @ViewBuilder
    func trailingTokenInfoView() -> some View {
        VStack(alignment: .trailing,
               spacing: 0) {
            Text(token.formattedBalanceUSD)
                .font(.currentFont(size: 16, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Color.foregroundDefault)
                .skeletonable()
                .skeletonCornerRadius(12)
            if let pctChange = token.marketPctChange24Hr {
                Text("\(pctChange.formatted(toMaxNumberAfterComa: 2))%")
                    .font(.currentFont(size: 14))
                    .foregroundStyle(pctChange > 0 ? Color.foregroundSuccess : secondaryColor)
                    .frame(height: token.isSkeleton ? 12 : 20)
                    .skeletonable()
                    .skeletonCornerRadius(10)
            }
        }
    }
}

#Preview {
    HomeWalletTokenRowView(token: MockEntitiesFabric.Tokens.mockUIToken())
}
