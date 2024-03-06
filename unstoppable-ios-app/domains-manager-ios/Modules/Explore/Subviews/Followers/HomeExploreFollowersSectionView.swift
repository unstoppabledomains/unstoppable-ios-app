//
//  HomeExploreFollowersSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.02.2024.
//

import SwiftUI

struct HomeExploreFollowersSectionView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: HomeExploreViewModel
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    @Environment(\.domainProfilesService) private var domainProfilesService

    var body: some View {
        if let profile = viewModel.selectedPublicDomainProfile {
            Section {
                gridWithFollowers(viewModel.getProfilesListForSelectedRelationshipType)
                    .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
            } header: {
                sectionHeaderView(profile: profile)
                    .padding(.init(vertical: 6))
            }
        }
    }
    
}

// MARK: - Private methods
private extension HomeExploreFollowersSectionView {
    @ViewBuilder
    func gridWithFollowers(_ followers: [DomainName]) -> some View {
        ListVGrid(data: followers,
                  verticalSpacing: 0,
                  horizontalSpacing: 16) { follower in
            Button {
                UDVibration.buttonTap.vibrate()
                logButtonPressedAnalyticEvents(button: .followerTile,
                                               parameters: [.domainName : follower])
                if let profile = domainProfilesService.getCachedDomainProfileDisplayInfo(for: follower) {
                    viewModel.didTapUserPublicDomainProfileDisplayInfo(profile)
                }
            } label: {
                HomeExploreFollowerCellView(domainName: follower)
            }
            .buttonStyle(.plain)
            .onAppear {
                viewModel.willDisplayFollower(domainName: follower)
            }
        }
    }
    
    @ViewBuilder
    func sectionHeaderView(profile: DomainProfileDisplayInfo) -> some View {
        HomeExploreFollowerRelationshipTypePickerView(profile: profile,
                                                      relationshipType: $viewModel.relationshipType)
            .padding(.init(vertical: 4))
    }
}

#Preview {
    HomeExploreFollowersSectionView()
        .environmentObject(MockEntitiesFabric.Explore.createViewModel())
}
