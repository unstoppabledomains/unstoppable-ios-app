//
//  HomeExploreTrendingProfilesSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.03.2024.
//

import SwiftUI

struct HomeExploreTrendingProfilesSectionView: View {
    
    @EnvironmentObject var viewModel: HomeExploreViewModel

    var body: some View {
        Section {
            ForEach(viewModel.trendingProfiles) { profile in
                HomeExploreTrendingProfileRowView(profile: profile)
            }
        } header: {
            Text(String.Constants.trending.localized())
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
                .padding(.init(vertical: 4))
        }
    }
}

#Preview {
    HomeExploreTrendingProfilesSectionView()
}