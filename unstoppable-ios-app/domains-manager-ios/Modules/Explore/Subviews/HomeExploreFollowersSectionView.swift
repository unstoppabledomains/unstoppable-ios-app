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
    
    var relationshipType: DomainProfileFollowerRelationshipType
    
    var body: some View {
        if !followersList.isEmpty {
            Section {
                gridWithFollowers(Array(followersList.prefix(numberOfFollowersToShow)))
            } header: {
                sectionHeaderView()
            }
        }
    }
    
}

// MARK: - Private methods
private extension HomeExploreFollowersSectionView {
    var followersList: [SerializedPublicDomainProfile] {
        switch relationshipType {
        case .followers:
            viewModel.followersList
        case .following:
            viewModel.followingsList
        }
    }
    
    var numberOfFollowersToShow: Int {
        isExpanded ? followersList.count : 2
    }
    
    @ViewBuilder
    func gridWithFollowers(_ followers: [SerializedPublicDomainProfile]) -> some View {
        ListVGrid(data: followers,
                  verticalSpacing: 0,
                  horizontalSpacing: 16) { follower in
            Button {
                UDVibration.buttonTap.vibrate()
                logButtonPressedAnalyticEvents(button: .followerTile,
                                               parameters: [.domainName : follower.profile.displayName ?? ""])
//                domainSelectedCallback(domain)
            } label: {
                HomeExploreFollowerCellView(follower: follower)
            }
            .buttonStyle(.plain)
        }
    }
    
    var sectionTitle: String {
        switch relationshipType {
        case .followers:
            String.Constants.followers.localized()
        case .following:
            String.Constants.following.localized()
        }
    }
    
    var isExpanded: Bool {
        viewModel.expandedFollowerTypes.contains(relationshipType)
    }
    
    @ViewBuilder
    func sectionHeaderView() -> some View {
        HomeWalletExpandableSectionHeaderView(title: sectionTitle,
                                              titleValue: nil,
                                              isExpandable: true,
                                              numberOfItemsInSection: followersList.count,
                                              isExpanded: isExpanded,
                                              actionCallback: {
            if isExpanded {
                viewModel.expandedFollowerTypes.remove(relationshipType)
            } else {
                viewModel.expandedFollowerTypes.insert(relationshipType)
            }
        })
    }
}

#Preview {
    HomeExploreFollowersSectionView(relationshipType: .followers)
        .environmentObject(MockEntitiesFabric.Explore.createViewModel())
}
