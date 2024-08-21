//
//  HomeExploreEmptyStateView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.03.2024.
//

import SwiftUI

struct HomeExploreEmptyStateView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: HomeExploreViewModel
    @Environment(\.analyticsViewName) var analyticsName

    let state: HomeExplore.EmptyState
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(state.title)
                    .font(.currentFont(size: 20, weight: .bold))
                Text(state.subtitle)
                    .font(.currentFont(size: 14))
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.foregroundSecondary)
            
            actionButtonView()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Private methods
private extension HomeExploreEmptyStateView {
    @ViewBuilder
    func actionButtonView() -> some View {
        if state.isActionAvailable {
            UDButtonView(text: state.actionTitle, style: state.actionStyle) {
                logButtonPressedAnalyticEvents(button: state.analyticButton)
                viewModel.didSelectActionInEmptyState(state)
            }
        }
    }
}

#Preview {
    HomeExploreEmptyStateView(state: .noFollowers)
}
