//
//  PublicProfileBadgesSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.03.2024.
//

import SwiftUI

struct PublicProfileBadgesSectionView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: PublicProfileView.PublicProfileViewModel
    @Environment(\.analyticsViewName) var analyticsName
    
    let sidePadding: CGFloat
    let badges: [DomainProfileBadgeDisplayInfo]
    
    var body: some View {
        VStack(spacing: sidePadding) {
            badgesTitle(badges: badges)
            badgesGrid(badges: badges)
        }
    }
}

// MARK: - Private methods
private extension PublicProfileBadgesSectionView {
    @ViewBuilder
    func badgesTitle(badges: [DomainProfileBadgeDisplayInfo]) -> some View {
        HStack {
            PublicProfilePrimaryLargeTextView(text: String.Constants.domainProfileSectionBadgesName.localized())
            PublicProfileSecondaryLargeTextView(text: "\(badges.count)")
            Spacer()
            Button {
                UDVibration.buttonTap.vibrate()
                viewModel.delegate?.publicProfileDidSelectOpenLeaderboard()
                logButtonPressedAnalyticEvents(button: .badgesLeaderboard)
            } label: {
                HStack(spacing: 8) {
                    Text(String.Constants.leaderboard.localized())
                        .font(.currentFont(size: 16, weight: .medium))
                        .frame(height: 24)
                    Image.arrowTopRight
                        .resizable()
                        .frame(width: 20,
                               height: 20)
                }
                .foregroundColor(.white).opacity(0.56)
            }
        }
    }
    
    @ViewBuilder
    func badgesGrid(badges: [DomainProfileBadgeDisplayInfo]) -> some View {
        LazyVGrid(columns: Array(repeating: .init(), count: 5)) {
            ForEach(badges, id: \.self) { badge in
                badgeView(badge: badge)
            }
        }
    }
    @ViewBuilder
    func badgeView(badge: DomainProfileBadgeDisplayInfo) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            viewModel.delegate?.publicProfileDidSelectBadge(badge, in: viewModel.domain.name)
            logButtonPressedAnalyticEvents(button: .badge, parameters: [.fieldName: badge.badge.name])
        } label: {
            ZStack {
                Color.white
                    .opacity(0.16)
                let badge = viewModel.badgesDisplayInfo?.first(where: { $0.badge.code == badge.badge.code }) ?? badge // Fix issue when SwiftUI could not pick up badge icon update sometimes
                let imagePadding: CGFloat = badge.badge.isUDBadge ? 8 : 4
                Image(uiImage: badge.icon ?? badge.defaultIcon)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .scaledToFill()
                    .clipped()
                    .clipShape(Circle())
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: imagePadding, leading: imagePadding,
                                        bottom: imagePadding, trailing: imagePadding))
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(Circle())
        }
        .task {
            viewModel.loadIconIfNeededFor(badge: badge)
        }
    }
}

#Preview {
    PublicProfileBadgesSectionView(sidePadding: 16,
                                   badges: [])
}
