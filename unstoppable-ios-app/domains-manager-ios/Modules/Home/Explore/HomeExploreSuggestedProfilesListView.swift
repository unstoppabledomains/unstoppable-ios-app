//
//  HomeExploreSuggestedProfilesListView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import SwiftUI

struct HomeExploreSuggestedProfilesListView: View {
    
    @EnvironmentObject var viewModel: HomeExploreViewModel

    var body: some View {
        List {
            ForEach(viewModel.suggestedProfiles) { profile in
                HomeExploreSuggestedProfileRowView(profileSuggestion: profile)
            }
        }
        .environmentObject(viewModel)
        .listStyle(.plain)
        .navigationTitle(String.Constants.suggestedForYou.localized())
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HomeExploreSuggestedProfilesListView()
    }
    .environmentObject(MockEntitiesFabric.Explore.createViewModel())
}
