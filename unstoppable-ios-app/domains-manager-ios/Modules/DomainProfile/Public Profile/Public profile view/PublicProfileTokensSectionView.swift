//
//  PublicProfileTokensSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct PublicProfileTokensSectionView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: PublicProfileView.PublicProfileViewModel
    @Environment(\.analyticsViewName) var analyticsName
    
    private let minNumberOfVisibleTokens: Int = 2
    
    var body: some View {
        if let tokens = viewModel.tokens {
            PublicProfileSeparatorView()
            titleView(tokens: tokens)
            LazyVStack(spacing: 20) {
                ForEach(getTokensListForCollapsedState(tokens: tokens)) { token in
                    HomeWalletTokenRowView(token: token,
                                           secondaryColor: .white.opacity(0.56))
                    .padding(EdgeInsets(top: -8, leading: 0, bottom: -8, trailing: 0))
                }
            }
            collapseViewIfAvailable(tokens: tokens)
        }
    }
}

// MARK: - Private methods
private extension PublicProfileTokensSectionView {
    func getTokensListForCollapsedState(tokens: [BalanceTokenUIDescription]) -> [BalanceTokenUIDescription] {
        if viewModel.isTokensCollapsed {
            return Array(tokens.prefix(minNumberOfVisibleTokens))
        } else {
            return tokens
        }
    }
}

// MARK: - Private methods
private extension PublicProfileTokensSectionView {
    @ViewBuilder
    func titleView(tokens: [BalanceTokenUIDescription]) -> some View {
        HStack {
            PublicProfilePrimaryLargeTextView(text: String.Constants.tokens.localized())
            PublicProfileSecondaryLargeTextView(text: "\(tokens.count)")
            Spacer()
            totalValueView(tokens: tokens)
        }
    }
    
    @ViewBuilder
    func totalValueView(tokens: [BalanceTokenUIDescription]) -> some View {
        Text(String.Constants.totalN.localized(BalanceStringFormatter.tokensBalanceString(tokens.totalBalanceUSD())))
            .foregroundStyle(Color.white.opacity(0.56))
            .font(.currentFont(size: 16, weight: .medium))
    }
    
    @ViewBuilder
    func collapseViewIfAvailable(tokens: [BalanceTokenUIDescription]) -> some View {
        if tokens.count > minNumberOfVisibleTokens {
            collapseView()
        }
    }
    
    var collapseViewTitle: String {
        if viewModel.isTokensCollapsed {
            return String.Constants.showMore.localized()
        }
        return String.Constants.collapse.localized()
    }
    
    var collapseViewImage: Image {
        if viewModel.isTokensCollapsed {
            return Image.chevronDown
        }
        return Image.chevronUp
    }
    
    @ViewBuilder
    func collapseView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            if viewModel.isTokensCollapsed {
                logButtonPressedAnalyticEvents(button: .showAll)
            } else {
                logButtonPressedAnalyticEvents(button: .hide)
            }
            withAnimation {
                viewModel.isTokensCollapsed.toggle()
            }
        } label: {
            HStack {
                collapseViewImage
                    .resizable()
                    .squareFrame(20)
                Text(collapseViewTitle)
                    .font(.currentFont(size: 16, weight: .medium))
            }
            .foregroundStyle(Color.white)
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    PublicProfileTokensSectionView()
}
