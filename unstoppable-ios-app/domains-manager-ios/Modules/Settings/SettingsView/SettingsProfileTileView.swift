//
//  SettingsProfileTileView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2024.
//

import SwiftUI

struct SettingsProfileTileView: View {

    @Environment(\.imageLoadingService) var imageLoadingService
    
    let profile: UserProfile
    
    @State private var rrIcon: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.backgroundOverlay
            contentView()
            domainsTag()
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderMuted, lineWidth: 1)
        }
        .frame(height: 132)
        .animation(.default, value: rrIcon)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension SettingsProfileTileView {
    func onAppear() {
        loadRRIconIfAvailable()
    }
    
    func loadRRIconIfAvailable() {
        if case .wallet(let wallet) = profile,
           let rrDomain = wallet.rrDomain {
            Task {
                rrIcon = await imageLoadingService.loadImage(from: .domainItemOrInitials(rrDomain, size: .default), downsampleDescription: .mid)
            }
        }
    }
    
    @ViewBuilder
    func contentView() -> some View {
        VStack(spacing: 8) {
            profileIconsView()
            profileTitles()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.foregroundSecondary)
        .padding(16)
    }
    
    @ViewBuilder
    func profileIconsView() -> some View {
        HStack {
                HStack(spacing: 0) {
                    profilePrimaryIconView()
                        .zIndex(2)
                    profileSecondaryIconView()
                }
            .overlay {
                Capsule()
//                    .stroke(Color.borderMuted, lineWidth: 1)
                    .stroke(Color.red, lineWidth: 1)
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    func profilePrimaryIconView() -> some View {
        Image.shieldKeyhole
            .resizable()
            .squareFrame(24)
            .padding(8)
            .background(Color.backgroundAccentEmphasis)
            .clipShape(Circle())
            .padding(4)
            .background(Color.backgroundOverlay)
            .clipShape(Circle())
    }
    
    @ViewBuilder
    func profileSecondaryIconView() -> some View {
        profileRRIconView()
            .offset(x: -12)
            .padding(.trailing, -12)
    }
    
    @ViewBuilder
    func profileRRIconView() -> some View {
        if let rrIcon {
            Image(uiImage: rrIcon)
                .resizable()
                .squareFrame(40)
                .clipShape(Circle())
                .padding(4)
                .background(Color.backgroundOverlay)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    func domainsTag() -> some View {
        Text("1")
            .foregroundStyle(Color.foregroundSecondary)
            .font(.currentFont(size: 14, weight: .semibold))
            .frame(height: 24)
            .padding(.horizontal, 8)
            .frame(minWidth: 24)
            .background(Color.backgroundSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            }
            .padding(4)
    }
    
    @ViewBuilder
    func profileTitles() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Vault")
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
                    .frame(height: 24)
                    .lineLimit(1)
                profileSubtitleView()
                    .frame(height: 20)
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    func profileSubtitleView() -> some View {
        switch profile {
        case .wallet(let wallet):
            if let rrDomain = wallet.rrDomain {
                HStack(spacing: 8) {
                    rrIconView()
                    profileSubtitleTextView(text: rrDomain.name)
                }
            } else if wallet.isAbleToSetRR {
                profileSubtitleTextView(text: String.Constants.noPrimaryDomain.localized(),
                                        foregroundColor: .foregroundWarning)
            }
        case .webAccount(let user):
            profileSubtitleTextView(text: user.email ?? "")
        }
    }
    
    @ViewBuilder
    func rrIconView() -> some View {
        Image.crownIcon
            .resizable()
            .squareFrame(16)
            .foregroundStyle(Color.foregroundSecondary)
    }
    
    @ViewBuilder
    func profileSubtitleTextView(text: String,
                                 foregroundColor: Color = .foregroundSecondary) -> some View {
        Text(text)
            .foregroundStyle(foregroundColor)
    }
}

#Preview {
    SettingsProfileTileView(profile: MockEntitiesFabric.Profile.createWalletProfile())
}
