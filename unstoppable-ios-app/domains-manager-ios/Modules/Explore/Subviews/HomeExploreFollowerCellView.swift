//
//  HomeExploreFollowerCellView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.02.2024.
//

import SwiftUI

struct HomeExploreFollowerCellView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService

    let follower: SerializedPublicDomainProfile
    private var domainName: String { "oleg.x" }
    @State private var icon: UIImage?
    @State private var cover: UIImage?

    var body: some View {
        viewForFollower()
            .onAppear(perform: onAppear)
//            .onChange(of: follower, perform: { _ in
//                loadAvatar()
//            })
    }
}

// MARK: - Private methods
private extension HomeExploreFollowerCellView {
    func onAppear() {
        loadAvatar()
    }
    
    func loadAvatar() {
        Task {
            // TODO: - Load images
            if let url = follower.profile.imagePath {
                icon = UIImage.Preview.previewLandscape
            } else {
                icon = await imageLoadingService.loadImage(from: .initials(domainName,
                                                                     size: .default,
                                                                     style: .accent), downsampleDescription: nil)
            }
            if let url = follower.profile.coverPath {
                cover = UIImage.Preview.previewPortrait
            }
        }
    }
    
    
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
        UIImageBridgeView(image: icon)
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
            if let name = follower.profile.displayName {
                Text(name)
                    .font(.currentFont(size: 14))
                    .foregroundStyle(Color.foregroundSecondary)
            }
        }
    }
}

#Preview {
    HomeExploreFollowerCellView(follower: MockEntitiesFabric.Explore.createFollowersProfiles()[0])
}
