//
//  HomeExploreSuggestedProfileRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import SwiftUI

struct HomeExploreSuggestedProfileRowView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: HomeExploreViewModel
    @Environment(\.imageLoadingService) private var imageLoadingService
    @Environment(\.analyticsViewName) var analyticsName
    
    let profileSuggestion: DomainProfileSuggestion
    
    @State private var avatar: UIImage?
    
    var body: some View {
        HStack(spacing: 2) {
            selectableProfileInfoView()
            Spacer()
            actionButtonView()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension HomeExploreSuggestedProfileRowView {
    func onAppear() {
        loadAvatar()
    }
    
    func loadAvatar() {
        Task {
            avatar = await imageLoadingService.loadImage(from: .domainNameInitials(profileSuggestion.domain,
                                                                                   size: .default),
                                                         downsampleDescription: nil)
            
            if let imagePath = profileSuggestion.imageUrl,
               let url = URL(string: imagePath) {
                avatar = await imageLoadingService.loadImage(from: .url(url, maxSize: nil), downsampleDescription: .mid)
            }
        }
    }
}

// MARK: - Private methods
private extension HomeExploreSuggestedProfileRowView {
    @ViewBuilder
    func selectableProfileInfoView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            viewModel.didSelectDomainProfileSuggestion(profileSuggestion)
        } label: {
            profileInfoView()
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func profileInfoView() -> some View {
        HStack(spacing: 16) {
            avatarView()
            profileDetailsInfoView()
        }
    }
    
    @ViewBuilder
    func avatarView() -> some View {
        ZStack(alignment: .bottomTrailing) {
            UIImageBridgeView(image: avatar)
                .squareFrame(40)
                .clipShape(Circle())
            reasonIndicatorView()
                .offset(x: 2,
                        y: 2)
        }
    }
    
    @ViewBuilder
    func reasonIndicatorView() -> some View {
        if let reason = profileSuggestion.getReasonToShow() {
            reason.icon
                .resizable()
                .squareFrame(16)
                .foregroundStyle(Color.black)
                .padding(2)
                .background(Color.white)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    func profileDetailsInfoView() -> some View {
        VStack(alignment: .leading) {
            Text(profileSuggestion.domain)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
            if let reason = profileSuggestion.getReasonToShow() {
                Text(reason.title)
                    .font(.currentFont(size: 14))
                    .foregroundStyle(Color.foregroundSecondary)
            }
        }
        .lineLimit(1)
    }
    
    @ViewBuilder
    func actionButtonView() -> some View {
        UDButtonView(text: String.Constants.follow.localized(),
                     style: .small(.raisedPrimary)) {
            viewModel.didSelectToFollowDomainName(profileSuggestion.domain)
        }
    }
}

#Preview {
    HomeExploreSuggestedProfileRowView(profileSuggestion: MockEntitiesFabric.ProfileSuggestions.createSuggestion())
}
