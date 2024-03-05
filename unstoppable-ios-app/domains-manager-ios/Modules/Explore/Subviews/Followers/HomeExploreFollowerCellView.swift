//
//  HomeExploreFollowerCellView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.02.2024.
//

import SwiftUI

struct HomeExploreFollowerCellView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService
    @Environment(\.domainProfilesService) private var domainProfilesService

    let domainName: DomainName
    @State private var profile: PublicDomainProfileDisplayInfo?
    @State private var pfpImage: UIImage?
    @State private var cover: UIImage?

    var body: some View {
        viewForFollower()
            .onAppear(perform: onAppear)
            .onChange(of: domainName) { newValue in
                loadProfile()
            }
    }
}

// MARK: - Private methods
private extension HomeExploreFollowerCellView {
    func onAppear() {
        loadProfile()
    }
    
    func loadProfile() {
        if let cachedProfile = domainProfilesService.getCachedPublicDomainProfileDisplayInfo(for: domainName) {
            setProfile(cachedProfile)
        } else {
            setProfile(nil)
            Task {
                let profile = try await domainProfilesService.fetchPublicDomainProfileDisplayInfo(for: domainName)
                setProfile(profile)
            }
        }
    }
    
    func setProfile(_ profile: PublicDomainProfileDisplayInfo?) {
        self.profile = profile
        self.pfpImage = nil
        self.cover = nil
        if let profile {
            loadAvatar(profile: profile)
        }
    }
    
    func loadAvatar(profile: PublicDomainProfileDisplayInfo) {
        Task {
            if let url = profile.pfpURL {
                pfpImage = await imageLoadingService.loadImage(from: .url(url, maxSize: nil),
                                                               downsampleDescription: .mid)
            } else {
                pfpImage = await imageLoadingService.loadImage(from: .initials(domainName,
                                                                     size: .default,
                                                                     style: .accent), downsampleDescription: nil)
            }
            
            cover = nil
            if let url = profile.bannerURL {
                pfpImage = await imageLoadingService.loadImage(from: .url(url, maxSize: nil),
                                                               downsampleDescription: .mid)
            }
        }
    }
}

// MARK: - Views methods
private extension HomeExploreFollowerCellView {
    @ViewBuilder
    func viewForFollower() -> some View {
        ZStack(alignment: .top) {
            Color.backgroundOverlay
            followerBackgroundView()
            VStack(spacing: 12) {
                followerAvatarView()
                followerNameInfoView()
            }
            .offset(y: 18)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(Color.borderMuted, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    func followerBackgroundView() -> some View {
        UIImageBridgeView(image: cover)
            .frame(height: 60)
            .background(Color.backgroundDefault)
    }
    
    @ViewBuilder
    func followerAvatarView() -> some View {
        UIImageBridgeView(image: pfpImage)
            .squareFrame(80)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .inset(by: 0.5)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            }
    }
    
    @ViewBuilder
    func followerNameInfoView() -> some View {
        VStack(spacing: 0) {
            Text(domainName)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
            if let name = profile?.profileName {
                Text(name)
                    .font(.currentFont(size: 14))
                    .foregroundStyle(Color.foregroundSecondary)
            }
        }
        .padding(.init(horizontal: 8))
        .lineLimit(1)
    }
}

#Preview {
    HomeExploreFollowerCellView(domainName: "preview.x")
}
