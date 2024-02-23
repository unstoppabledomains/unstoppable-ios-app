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
    
    var body: some View {
        Section {
            gridWithFollowers(viewModel.followersList)
        }
    }
    
}

// MARK: - Private methods
private extension HomeExploreFollowersSectionView {
    @ViewBuilder
    func gridWithFollowers(_ followers: [SerializedPublicDomainProfile]) -> some View {
        ListVGrid(data: followers,
                  verticalSpacing: 16,
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
}

#Preview {
    HomeExploreFollowersSectionView()
        .environmentObject(MockEntitiesFabric.Explore.createViewModel())
}
