//
//  HomeExploreTrendingProfilesSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.03.2024.
//

import SwiftUI

struct HomeExploreTrendingProfilesSectionView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: HomeExploreViewModel
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    @Environment(\.domainProfilesService) private var domainProfilesService

    var body: some View {
        Section {
            gridWithDomains(viewModel.trendingProfiles)
        } header: {
            Text(String.Constants.trending.localized())
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
                .padding(.init(vertical: 4))
        }
    }
}

// MARK: - Private methods
private extension HomeExploreTrendingProfilesSectionView {
    @ViewBuilder
    func gridWithDomains(_ followers: [DomainName]) -> some View {
        ListVGrid(data: followers,
                  verticalSpacing: 0,
                  horizontalSpacing: 16) { follower in
            Button {
                UDVibration.buttonTap.vibrate()
                logButtonPressedAnalyticEvents(button: .trendingProfileTile,
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
}

#Preview {
    HomeExploreTrendingProfilesSectionView()
}
