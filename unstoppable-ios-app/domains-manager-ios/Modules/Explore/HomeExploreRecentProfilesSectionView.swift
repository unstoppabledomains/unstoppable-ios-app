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
        
    }
}

#Preview {
    HomeExploreRecentProfilesSectionView()
}
