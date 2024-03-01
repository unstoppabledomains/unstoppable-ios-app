//
//  HomeExploreRecentProfilesSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.03.2024.
//

import SwiftUI

struct HomeExploreRecentProfilesSectionView: View {
    
    @EnvironmentObject var viewModel: HomeExploreViewModel

    var body: some View {
        if !viewModel.recentProfiles.isEmpty {
            Section {
                recentProfilesListView()
            } header: {
                recentProfilesSectionHeaderView()
            }
        }
    }
}

// MARK: - Private methods
private extension HomeExploreRecentProfilesSectionView {
    @ViewBuilder
    func recentProfilesListView() -> some View {
        ForEach(viewModel.recentProfiles) { profile in
            HomeExploreTrendingProfileRowView(profile: profile)
        }
    }
    
    @ViewBuilder
    func recentProfilesSectionHeaderView() -> some View {
        HStack {
            Text("Recent")
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
            
            Spacer()
            
            Button {
                UDVibration.buttonTap.vibrate()
                viewModel.clearRecentSearchButtonPressed()
            } label: {
                Image.searchClearIcon
                    .resizable()
                    .squareFrame(20)
                    .foregroundStyle(Color.foregroundSecondary)
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    HomeExploreRecentProfilesSectionView()
}
