//
//  HomeExploreTrendingProfileRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.02.2024.
//

import SwiftUI

struct HomeExploreTrendingProfileRowView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: HomeExploreViewModel
    @Environment(\.imageLoadingService) var imageLoadingService
    @Environment(\.analyticsViewName) var analyticsName
    let profile: HomeExplore.TrendingProfile
    
    @State private var avatar: UIImage?
    
    var body: some View {
        clickableContentView()
        .onAppear(perform: onAppear)
    }
    
}

// MARK: - Private methods
private extension HomeExploreTrendingProfileRowView {
    func onAppear() {
        loadAvatar()
    }
    
    func loadAvatar() {
        Task {
            avatar = await imageLoadingService.loadImage(from: .domainNameInitials(profile.domainName,
                                                                                   size: .default),
                                                         downsampleDescription: nil)
            if let url = profile.avatarURL,
               let avatar = await imageLoadingService.loadImage(from: .url(url, maxSize: nil),
                                                                downsampleDescription: .mid) {
                self.avatar = avatar
            }
        }
    }
}

// MARK: - Private methods
private extension HomeExploreTrendingProfileRowView {
    @ViewBuilder
    func clickableContentView() -> some View {
        UDCollectionListRowButton(content: {
            contentView()
        }, callback: {
            UDVibration.buttonTap.vibrate()
            logAnalytic(event: .trendingProfilePressed, parameters: [.domainName : profile.domainName])
            viewModel.didTapTrendingProfile(profile)
        })
    }
    
    @ViewBuilder
    func contentView() -> some View {
        HStack(spacing: 16) {
            avatarView()
            profileInfoView()
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    func avatarView() -> some View {
        UIImageBridgeView(image: avatar,
                          width: 20,
                          height: 20)
        .squareFrame(40)
        .clipShape(Circle())
    }
    
    @ViewBuilder
    func profileInfoView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(profile.domainName)
                .foregroundStyle(Color.foregroundDefault)
                .font(.currentFont(size: 16, weight: .medium))
                .frame(height: 24)
            if let profileInfoText {
                Text(profileInfoText)
                    .foregroundStyle(Color.foregroundSecondary)
                    .font(.currentFont(size: 14))
                    .frame(height: 20)
                    .truncationMode(.middle)
            }
        }
        .lineLimit(1)
    }
    
    var profileInfoText: String? {
        if let profileDisplayNameText,
           let followersInfoText  {
            return "\(profileDisplayNameText) · \(followersInfoText)"
        } else if let profileDisplayNameText {
            return profileDisplayNameText
        } else if let followersInfoText {
            return followersInfoText
        }
        
        return nil
    }
    
    var profileDisplayNameText: String? {
        if !profile.profileName.isEmpty {
            return profile.profileName
        }
        return nil
    }
    
    var followersInfoText: String? {
        if profile.followersCount > 0 {
            return String.Constants.pluralNFollowers.localized(profile.followersCount, profile.followersCount)
        }
        return nil
    }
}

#Preview {
    HomeExploreTrendingProfileRowView(profile: MockEntitiesFabric.Explore.createTrendingProfiles()[0])
}
